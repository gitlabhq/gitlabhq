# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project fork', feature_category: :source_code_management do
  include ListboxHelpers
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository, description: 'some description') }

  before do
    sign_in(user)
  end

  shared_examples 'fork button on project page' do
    context 'when the user has access to only one namespace and has already forked the project', :js do
      before do
        fork_project(project, user, repository: true, namespace: user.namespace)
      end

      it 'allows user to go to their fork' do
        visit project_path(project)

        path = namespace_project_path(user, user.fork_of(project))

        fork_button = find_link 'Fork'
        expect(fork_button['href']).to include(path)
        expect(fork_button['class']).not_to include('disabled')
      end
    end

    shared_examples 'fork button creates new fork' do
      it 'allows user to fork the project from the project page' do
        visit project_path(project)

        path = new_project_fork_path(project)

        fork_button = find_link 'Fork'
        expect(fork_button['href']).to include(path)
        expect(fork_button['class']).not_to include('disabled')
      end

      context 'when the user cannot fork the project' do
        let(:project) do
          # Disabling the repository makes sure that the user cannot fork the project
          create(:project, :public, :repository, :repository_disabled, description: 'some description')
        end

        it 'disables fork button on project page' do
          visit project_path(project)

          path = new_project_fork_path(project)

          fork_button = find_link 'Fork'
          expect(fork_button['href']).to include(path)
          expect(fork_button['class']).to include('disabled')
        end
      end
    end

    context 'when the user has not already forked the project', :js do
      it_behaves_like 'fork button creates new fork'
    end

    context 'when the user has access to more than one namespace', :js do
      let(:group) { create(:group) }

      before do
        group.add_developer(user)
      end

      it_behaves_like 'fork button creates new fork'
    end
  end

  shared_examples 'create fork page' do |fork_page_text|
    before do
      project.project_feature.update_attribute(
        :forking_access_level, forking_access_level)
    end

    context 'forking is enabled', :js do
      let(:forking_access_level) { ProjectFeature::ENABLED }

      it 'enables fork button' do
        visit project_path(project)

        fork_button = find_link 'Fork'
        expect(fork_button['class']).not_to include('disabled')
      end

      it 'renders new project fork page' do
        visit new_project_fork_path(project)

        expect(page).to have_text(fork_page_text)
      end
    end

    context 'forking is disabled' do
      let(:forking_access_level) { ProjectFeature::DISABLED }

      it 'render a disabled fork button', :js do
        visit project_path(project)

        fork_button = find_link 'Fork'

        expect(fork_button['class']).to include('disabled')
        expect(page).to have_selector('[data-testid="forks-count"]')
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
        it 'render a disabled fork button', :js do
          visit project_path(project)

          fork_button = find_link 'Fork'

          expect(fork_button['class']).to include('disabled')
          expect(page).to have_selector('[data-testid="forks-count"]')
        end

        it 'does not render new project fork page' do
          visit new_project_fork_path(project)

          expect(page.status_code).to eq(404)
        end
      end

      context 'user is a team member', :js do
        before do
          project.add_developer(user)
        end

        it 'enables fork button' do
          visit project_path(project)

          fork_button = find_link 'Fork'

          expect(fork_button['class']).not_to include('disabled')
          expect(page).to have_selector('[data-testid="forks-count"]')
        end

        it 'renders new project fork page' do
          visit new_project_fork_path(project)

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

        forks_count_button = find_by_testid('forks-count')
        expect(forks_count_button).to have_content("2")
      end
    end
  end
end

private

def create_fork(group_obj = group)
  visit project_path(project)

  click_link 'Fork'

  submit_form(group_obj)
  wait_for_requests
end

def create_forks
  create_fork
  create_fork(group2)
end
