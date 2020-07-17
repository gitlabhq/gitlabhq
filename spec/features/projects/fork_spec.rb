# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project fork' do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }

  before do
    sign_in user
  end

  it 'allows user to fork project' do
    visit project_path(project)

    expect(page).not_to have_css('a.disabled', text: 'Select')
  end

  it 'disables fork button when user has exceeded project limit' do
    user.projects_limit = 0
    user.save!

    visit project_path(project)

    expect(page).to have_css('a.disabled', text: 'Fork')
  end

  context 'forking enabled / disabled in project settings' do
    before do
      project.project_feature.update_attribute(
        :forking_access_level, forking_access_level)
    end

    context 'forking is enabled' do
      let(:forking_access_level) { ProjectFeature::ENABLED }

      it 'enables fork button' do
        visit project_path(project)

        expect(page).to have_css('a', text: 'Fork')
        expect(page).not_to have_css('a.disabled', text: 'Select')
      end

      it 'renders new project fork page' do
        visit new_project_fork_path(project)

        expect(page.status_code).to eq(200)
        expect(page).to have_text(' Select a namespace to fork the project ')
      end
    end

    context 'forking is disabled' do
      let(:forking_access_level) { ProjectFeature::DISABLED }

      it 'does not render fork button' do
        visit project_path(project)

        expect(page).not_to have_css('a', text: 'Fork')
      end

      it 'does not render new project fork page' do
        visit new_project_fork_path(project)

        expect(page.status_code).to eq(404)
      end
    end

    context 'forking is private' do
      let(:forking_access_level) { ProjectFeature::PRIVATE }

      before do
        project.update(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      context 'user is not a team member' do
        it 'does not render fork button' do
          visit project_path(project)

          expect(page).not_to have_css('a', text: 'Fork')
        end

        it 'does not render new project fork page' do
          visit new_project_fork_path(project)

          expect(page.status_code).to eq(404)
        end
      end

      context 'user is a team member' do
        before do
          project.add_developer(user)
        end

        it 'enables fork button' do
          visit project_path(project)

          expect(page).to have_css('a', text: 'Fork')
          expect(page).not_to have_css('a.disabled', text: 'Fork')
        end

        it 'renders new project fork page' do
          visit new_project_fork_path(project)

          expect(page.status_code).to eq(200)
          expect(page).to have_text(' Select a namespace to fork the project ')
        end
      end
    end
  end

  it 'forks the project', :sidekiq_might_not_need_inline do
    visit project_path(project)

    click_link 'Fork'

    page.within '.fork-thumbnail-container' do
      click_link 'Select'
    end

    expect(page).to have_content 'Forked from'

    visit project_path(project)

    expect(page).to have_content(/new merge request/i)

    page.within '.nav-sidebar' do
      first(:link, 'Merge Requests').click
    end

    expect(page).to have_content(/new merge request/i)

    page.within '#content-body' do
      click_link('New merge request')
    end

    expect(current_path).to have_content(/#{user.namespace.path}/i)
  end

  it 'shows avatars when Gravatar is disabled' do
    stub_application_setting(gravatar_enabled: false)

    visit project_path(project)

    click_link 'Fork'

    page.within('.fork-thumbnail-container') do
      expect(page).to have_css('div.identicon')
    end
  end

  it 'shows the forked project on the list' do
    visit project_path(project)

    click_link 'Fork'

    page.within '.fork-thumbnail-container' do
      click_link 'Select'
    end

    visit project_forks_path(project)

    forked_project = user.fork_of(project.reload)

    page.within('.js-projects-list-holder') do
      expect(page).to have_content("#{forked_project.namespace.human_name} / #{forked_project.name}")
    end

    forked_project.update!(path: 'test-crappy-path')

    visit project_forks_path(project)

    page.within('.js-projects-list-holder') do
      expect(page).to have_content("#{forked_project.namespace.human_name} / #{forked_project.name}")
    end
  end

  context 'when the project is private' do
    let(:project) { create(:project, :repository) }
    let(:another_user) { create(:user, name: 'Mike') }

    before do
      project.add_reporter(user)
      project.add_reporter(another_user)
    end

    it 'renders private forks of the project' do
      visit project_path(project)

      another_project_fork = Projects::ForkService.new(project, another_user).execute

      click_link 'Fork'

      page.within '.fork-thumbnail-container' do
        click_link 'Select'
      end

      visit project_forks_path(project)

      page.within('.js-projects-list-holder') do
        user_project_fork = user.fork_of(project.reload)
        expect(page).to have_content("#{user_project_fork.namespace.human_name} / #{user_project_fork.name}")
      end

      expect(page).not_to have_content("#{another_project_fork.namespace.human_name} / #{another_project_fork.name}")
    end
  end

  context 'when the user already forked the project' do
    before do
      create(:project, :repository, name: project.name, namespace: user.namespace)
    end

    it 'renders error' do
      visit project_path(project)

      click_link 'Fork'

      page.within '.fork-thumbnail-container' do
        click_link 'Select'
      end

      expect(page).to have_content "Name has already been taken"
    end
  end

  context 'maintainer in group' do
    let(:group) { create(:group) }

    before do
      group.add_maintainer(user)
    end

    it 'allows user to fork project to group or to user namespace', :js do
      visit project_path(project)
      wait_for_requests

      expect(page).not_to have_css('a.disabled', text: 'Fork')

      click_link 'Fork'

      expect(page).to have_css('.fork-thumbnail')
      expect(page).to have_css('.group-row')
      expect(page).not_to have_css('.fork-thumbnail.disabled')
    end

    it 'allows user to fork project to group and not user when exceeded project limit', :js do
      user.projects_limit = 0
      user.save!

      visit project_path(project)
      wait_for_requests

      expect(page).not_to have_css('a.disabled', text: 'Fork')

      click_link 'Fork'

      expect(page).to have_css('.fork-thumbnail.disabled')
      expect(page).to have_css('.group-row')
    end

    it 'links to the fork if the project was already forked within that namespace', :sidekiq_might_not_need_inline, :js do
      forked_project = fork_project(project, user, namespace: group, repository: true)

      visit new_project_fork_path(project)
      wait_for_requests

      expect(page).to have_css('.group-row a.btn', text: 'Go to fork')

      click_link 'Go to fork'

      expect(current_path).to eq(project_path(forked_project))
    end
  end
end
