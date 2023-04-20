# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Group Runners", feature_category: :runner_fleet do
  include Features::RunnersHelpers
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:group_owner) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  before do
    group.add_owner(group_owner)
    sign_in(group_owner)
  end

  describe "Group runners page", :js do
    describe "legacy runners registration" do
      let_it_be(:group_registration_token) { group.runners_token }

      before do
        stub_feature_flags(create_runner_workflow_for_namespace: false)

        visit group_runners_path(group)
      end

      it_behaves_like "shows and resets runner registration token" do
        let(:dropdown_text) { 'Register a group runner' }
        let(:registration_token) { group_registration_token }
      end
    end

    context "with no runners" do
      before do
        visit group_runners_path(group)
      end

      it_behaves_like 'shows no runners registered'

      it 'shows tabs with total counts equal to 0' do
        expect(page).to have_link('All 0')
        expect(page).to have_link('Group 0')
        expect(page).to have_link('Project 0')
      end
    end

    context "with an online group runner" do
      let!(:group_runner) do
        create(:ci_runner, :group, groups: [group], description: 'runner-foo', contacted_at: Time.zone.now)
      end

      before do
        visit group_runners_path(group)
      end

      it_behaves_like 'shows runner in list' do
        let(:runner) { group_runner }
      end

      it_behaves_like 'pauses, resumes and deletes a runner' do
        let(:runner) { group_runner }
      end

      it 'shows an editable group badge' do
        within_runner_row(group_runner.id) do
          expect(find_link('Edit')[:href]).to end_with(edit_group_runner_path(group, group_runner))

          expect(page).to have_selector '.badge', text: s_('Runners|Group')
        end
      end

      context 'when description does not match' do
        before do
          input_filtered_search_keys('runner-baz')
        end

        it_behaves_like 'shows no runners found'

        it 'shows no runner' do
          expect(page).not_to have_content 'runner-foo'
        end
      end
    end

    context "with an online project runner" do
      let!(:project_runner) do
        create(:ci_runner, :project, projects: [project], description: 'runner-bar', contacted_at: Time.zone.now)
      end

      before do
        visit group_runners_path(group)
      end

      it_behaves_like 'shows runner in list' do
        let(:runner) { project_runner }
      end

      it_behaves_like 'pauses, resumes and deletes a runner' do
        let(:runner) { project_runner }
      end

      it 'shows an editable project runner' do
        within_runner_row(project_runner.id) do
          expect(find_link('Edit')[:href]).to end_with(edit_group_runner_path(group, project_runner))

          expect(page).to have_selector '.badge', text: s_('Runners|Project')
        end
      end
    end

    context "with an online instance runner" do
      let!(:instance_runner) do
        create(:ci_runner, :instance, description: 'runner-baz', contacted_at: Time.zone.now)
      end

      before do
        visit group_runners_path(group)
      end

      context "when selecting 'Show only inherited'" do
        before do
          find("[data-testid='runner-membership-toggle'] button").click

          wait_for_requests
        end

        it_behaves_like 'shows runner in list' do
          let(:runner) { instance_runner }
        end

        it 'shows runner details page' do
          click_link("##{instance_runner.id} (#{instance_runner.short_sha})")

          expect(current_url).to include(group_runner_path(group, instance_runner))
          expect(page).to have_content "#{s_('Runners|Description')} runner-baz"
        end
      end
    end

    context 'with a multi-project runner' do
      let(:project) { create(:project, group: group) }
      let(:project_2) { create(:project, group: group) }
      let!(:runner) { create(:ci_runner, :project, projects: [project, project_2], description: 'group-runner') }

      it 'user cannot remove the project runner' do
        visit group_runners_path(group)

        within_runner_row(runner.id) do
          expect(page).not_to have_button 'Delete runner'
        end
      end
    end

    context "with multiple runners" do
      before do
        create(:ci_runner, :group, groups: [group], description: 'runner-foo')
        create(:ci_runner, :group, groups: [group], description: 'runner-bar')

        visit group_runners_path(group)
      end

      it_behaves_like 'deletes runners in bulk' do
        let(:runner_count) { '2' }
      end
    end

    describe 'filtered search' do
      before do
        visit group_runners_path(group)
      end

      it 'allows user to search by paused and status', :js do
        focus_filtered_search

        page.within(search_bar_selector) do
          expect(page).to have_link(s_('Runners|Paused'))
          expect(page).to have_content('Status')
        end
      end
    end

    describe 'filter by tag' do
      let!(:runner_1) { create(:ci_runner, :group, groups: [group], description: 'runner-blue', tag_list: ['blue']) }
      let!(:runner_2) { create(:ci_runner, :group, groups: [group], description: 'runner-red', tag_list: ['red']) }

      before do
        visit group_runners_path(group)
      end

      it_behaves_like 'filters by tag' do
        let(:tag) { 'blue' }
        let(:found_runner) { runner_1.description }
        let(:missing_runner) { runner_2.description }
      end
    end
  end

  describe "Group runner create page", :js do
    before do
      visit new_group_runner_path(group)
    end

    it_behaves_like 'creates runner and shows register page' do
      let(:register_path_pattern) { register_group_runner_path(group, '.*') }
    end
  end

  describe "Group runner show page", :js do
    let_it_be(:group_runner) do
      create(:ci_runner, :group, groups: [group], description: 'runner-foo')
    end

    let_it_be(:group_runner_job) { create(:ci_build, runner: group_runner) }

    before do
      visit group_runner_path(group, group_runner)
    end

    it 'user views runner details' do
      expect(page).to have_content "#{s_('Runners|Description')} runner-foo"
    end

    it_behaves_like 'shows runner jobs tab' do
      let(:job_count) { '1' }
      let(:job) { group_runner_job }
    end
  end

  describe "Group runner edit page", :js do
    context 'when updating a group runner' do
      let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }

      before do
        visit edit_group_runner_path(group, group_runner)
        wait_for_requests
      end

      it_behaves_like 'submits edit runner form' do
        let(:runner) { group_runner }
        let(:runner_page_path) { group_runner_path(group, group_runner) }
      end
    end

    context 'when updating a project runner' do
      let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }

      before do
        visit edit_group_runner_path(group, project_runner)
        wait_for_requests
      end

      it_behaves_like 'submits edit runner form' do
        let(:runner) { project_runner }
        let(:runner_page_path) { group_runner_path(group, project_runner) }
      end
    end
  end
end
