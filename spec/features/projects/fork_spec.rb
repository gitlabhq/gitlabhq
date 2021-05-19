# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project fork' do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository, description: 'some description') }

  before do
    sign_in(user)
  end

  shared_examples 'fork button on project page' do
    it 'allows user to fork project from the project page' do
      visit project_path(project)

      expect(page).not_to have_css('a.disabled', text: 'Fork')
    end

    context 'user has exceeded personal project limit' do
      before do
        user.update!(projects_limit: 0)
      end

      it 'disables fork button on project page' do
        visit project_path(project)

        expect(page).to have_css('a.disabled', text: 'Fork')
      end
    end
  end

  shared_examples 'create fork page' do |fork_page_text|
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
        expect(page).to have_text(fork_page_text)
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
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
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
          expect(page).to have_text(fork_page_text)
        end
      end
    end
  end

  it_behaves_like 'fork button on project page'
  it_behaves_like 'create fork page', 'Fork project'

  context 'fork form', :js do
    let(:group) { create(:group) }
    let(:user) { create(:group_member, :maintainer, user: create(:user), group: group ).user }

    def submit_form
      select(group.name)
      click_button 'Fork project'
    end

    it 'forks the project', :sidekiq_might_not_need_inline do
      visit new_project_fork_path(project)
      submit_form

      expect(page).to have_content 'Forked from'
    end

    it 'shows the new forked project on the forks page' do
      visit new_project_fork_path(project)
      submit_form
      wait_for_requests

      visit project_forks_path(project)

      page.within('.js-projects-list-holder') do
        expect(page).to have_content("#{group.name} / #{project.name}")
      end
    end

    it 'shows the filled in info forked project on the forks page' do
      fork_name = 'some-name'
      visit new_project_fork_path(project)
      fill_in('fork-name', with: fork_name, fill_options: { clear: :backspace })
      fill_in('fork-slug', with: fork_name, fill_options: { clear: :backspace })
      submit_form
      wait_for_requests

      visit project_forks_path(project)

      page.within('.js-projects-list-holder') do
        expect(page).to have_content("#{group.name} / #{fork_name}")
      end
    end
  end

  context 'with fork_project_form feature flag disabled' do
    before do
      stub_feature_flags(fork_project_form: false)
      sign_in(user)
    end

    it_behaves_like 'fork button on project page'

    context 'user has exceeded personal project limit' do
      before do
        user.update!(projects_limit: 0)
      end

      context 'with a group to fork to' do
        let!(:group) { create(:group).tap { |group| group.add_owner(user) } }

        it 'allows user to fork only to the group on fork page', :js do
          visit new_project_fork_path(project)

          to_personal_namespace = find('[data-qa-selector=fork_namespace_button].disabled')
          to_group = find(".fork-groups button[data-qa-name=#{group.name}]")

          expect(to_personal_namespace).not_to be_nil
          expect(to_group).not_to be_disabled
        end
      end
    end

    it_behaves_like 'create fork page', ' Select a namespace to fork the project '

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
        first(:link, 'Merge requests').click
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
        expect(page).to have_css('span.identicon')
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
end
