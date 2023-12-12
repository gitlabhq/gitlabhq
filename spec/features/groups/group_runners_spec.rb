# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Group Runners", feature_category: :fleet_visibility do
  include Features::RunnersHelpers
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:group_owner) { create(:user) }
  let_it_be(:group_maintainer) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  before_all do
    group.add_owner(group_owner)
    group.add_maintainer(group_maintainer)
  end

  describe "Group runners page", :js do
    context 'when logged in as group maintainer' do
      before do
        sign_in(group_maintainer)
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
        let_it_be(:group_runner) do
          create(:ci_runner, :group, groups: [group], description: 'runner-foo', contacted_at: Time.zone.now)
        end

        before do
          visit group_runners_path(group)
        end

        it_behaves_like 'shows runner summary and navigates to details' do
          let(:runner) { group_runner }
          let(:runner_page_path) { group_runner_path(group, group_runner) }
        end

        it 'shows a group runner badge' do
          within_runner_row(group_runner.id) do
            expect(page).to have_selector '.badge', text: s_('Runners|Group')
          end
        end

        context 'when description does not match' do
          before do
            input_filtered_search_keys('runner-baz')
          end

          it_behaves_like 'shows no runners found'
        end
      end

      context "with an online project runner" do
        let_it_be(:project_runner) do
          create(:ci_runner, :project, projects: [project], description: 'runner-bar', contacted_at: Time.zone.now)
        end

        before do
          visit group_runners_path(group)
        end

        it_behaves_like 'shows runner summary and navigates to details' do
          let(:runner) { project_runner }
          let(:runner_page_path) { group_runner_path(group, project_runner) }
        end

        it 'shows a project runner badge' do
          within_runner_row(project_runner.id) do
            expect(page).to have_selector '.badge', text: s_('Runners|Project')
          end
        end
      end

      context "with an online instance runner" do
        let_it_be(:instance_runner) do
          create(:ci_runner, :instance, description: 'runner-baz', contacted_at: Time.zone.now)
        end

        before do
          visit group_runners_path(group)
        end

        context "when selecting 'Show only inherited'" do
          before do
            find("[data-testid='runner-membership-toggle'] button").click
          end

          it_behaves_like 'shows runner summary and navigates to details' do
            let(:runner) { instance_runner }
            let(:runner_page_path) { group_runner_path(group, instance_runner) }
          end
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
        let!(:rnr_1) { create(:ci_runner, :group, groups: [group], description: 'runner-blue', tag_list: ['blue']) }
        let!(:rnr_2) { create(:ci_runner, :group, groups: [group], description: 'runner-red', tag_list: ['red']) }

        before do
          visit group_runners_path(group)
        end

        it_behaves_like 'filters by tag' do
          let(:tag) { 'blue' }
          let(:found_runner) { rnr_1.description }
          let(:missing_runner) { rnr_2.description }
        end
      end
    end

    context 'when logged in as group owner' do
      before do
        sign_in(group_owner)
      end

      context "with an online group runner" do
        let_it_be(:group_runner) do
          create(:ci_runner, :group, groups: [group], description: 'runner-foo', contacted_at: Time.zone.now)
        end

        before do
          visit group_runners_path(group)
        end

        it_behaves_like 'pauses, resumes and deletes a runner' do
          let(:runner) { group_runner }
        end

        it 'shows an edit link' do
          within_runner_row(group_runner.id) do
            expect(find_link('Edit')[:href]).to end_with(edit_group_runner_path(group, group_runner))
          end
        end
      end

      context "with an online project runner" do
        let_it_be(:project_runner) do
          create(:ci_runner, :project, projects: [project], description: 'runner-bar', contacted_at: Time.zone.now)
        end

        before do
          visit group_runners_path(group)
        end

        it_behaves_like 'pauses, resumes and deletes a runner' do
          let(:runner) { project_runner }
        end

        it 'shows an editable project runner' do
          within_runner_row(project_runner.id) do
            expect(find_link('Edit')[:href]).to end_with(edit_group_runner_path(group, project_runner))
          end
        end
      end

      context 'with a multi-project runner' do
        let_it_be(:project) { create(:project, group: group) }
        let_it_be(:project_2) { create(:project, group: group) }
        let_it_be(:runner) do
          create(:ci_runner, :project, projects: [project, project_2], description: 'group-runner')
        end

        it 'owner cannot remove the project runner' do
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
    end
  end

  describe "Group runner create page", :js do
    before do
      sign_in(group_owner)

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

    let_it_be(:group_runner_job) { create(:ci_build, runner: group_runner, project: project) }

    context 'when logged in as group maintainer' do
      before do
        sign_in(group_maintainer)

        visit group_runner_path(group, group_runner)
      end

      it 'user views runner details' do
        expect(page).to have_content "#{s_('Runners|Description')} runner-foo"
      end
    end

    context 'when logged in as group owner' do
      before do
        sign_in(group_owner)

        visit group_runner_path(group, group_runner)
      end

      it_behaves_like 'shows runner jobs tab' do
        let(:job_count) { '1' }
        let(:job) { group_runner_job }
      end
    end
  end

  describe "Group runner edit page", :js do
    before do
      sign_in(group_owner)
    end

    context 'when updating a group runner' do
      let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }

      before do
        visit edit_group_runner_path(group, group_runner)
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
      end

      it_behaves_like 'submits edit runner form' do
        let(:runner) { project_runner }
        let(:runner_page_path) { group_runner_path(group, project_runner) }
      end

      it_behaves_like 'shows locked field'
    end
  end
end
