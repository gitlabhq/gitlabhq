# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project fork', feature_category: :projects do
  include ListboxHelpers
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

      it 'render a disabled fork button' do
        visit project_path(project)

        expect(page).to have_css('a.disabled', text: 'Fork')
        expect(page).to have_css('a.count', text: '0')
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
        it 'render a disabled fork button' do
          visit project_path(project)

          expect(page).to have_css('a.disabled', text: 'Fork')
          expect(page).to have_css('a.count', text: '0')
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
          expect(page).to have_css('a.count', text: '0')
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
    let(:group2) { create(:group) }
    let(:user) { create(:group_member, :maintainer, user: create(:user), group: group).user }

    def submit_form(group_obj = group)
      click_button(s_('ForkProject|Select a namespace'))
      send_keys group_obj.name
      select_listbox_item(group_obj.name)
      click_button 'Fork project'
    end

    it 'forks the project', :sidekiq_might_not_need_inline do
      visit new_project_fork_path(project)
      submit_form

      expect(page).to have_content 'Forked from'
    end

    it 'redirects to the source project when cancel is clicked' do
      visit new_project_fork_path(project)
      click_on 'Cancel'

      expect(page).to have_current_path(project_path(project))
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

    context 'when user is a maintainer in multiple groups' do
      before do
        create(:group_member, :maintainer, user: user, group: group2)
      end

      it "increments the fork counter on the source project's page", :sidekiq_might_not_need_inline do
        create_forks

        visit project_path(project)

        expect(page).to have_css('.fork-count', text: 2)
      end
    end
  end
end

private

def create_fork(group_obj = group)
  visit project_path(project)
  find('.fork-btn').click
  submit_form(group_obj)
  wait_for_requests
end

def create_forks
  create_fork
  create_fork(group2)
end
