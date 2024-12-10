# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Group maintainer sees runner list", :freeze_time, :js, feature_category: :fleet_visibility do
  include Features::RunnersHelpers

  let_it_be(:group_maintainer) { create(:user) }
  let_it_be(:group) { create(:group, maintainers: group_maintainer) }
  let_it_be(:project) { create(:project, group: group) }

  before_all do
    freeze_time # Freeze time before `let_it_be` runs, so that runner statuses are frozen during execution
  end

  after :all do
    unfreeze_time
  end

  before do
    sign_in(group_maintainer)

    visit group_runners_path(group)
  end

  context "with an online group runner" do
    let_it_be(:group_runner) do
      create(:ci_runner, :group, :almost_offline, groups: [group], description: 'runner-foo')
    end

    describe 'from runner list' do
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

    describe 'from runner details' do
      before do
        visit group_runner_path(group, group_runner)
      end

      it 'shows runner details' do
        expect(page).to have_content "Description runner-foo"
      end
    end
  end

  context "with an online project runner" do
    let_it_be(:project_runner) do
      create(:ci_runner, :project, :almost_offline, projects: [project], description: 'runner-bar')
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
      create(:ci_runner, :instance, :almost_offline, description: 'runner-baz')
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

  context "with no runners" do
    it_behaves_like 'shows no runners registered'

    it 'shows tabs with total counts equal to 0' do
      expect(page).to have_link('All 0')
      expect(page).to have_link('Group 0')
      expect(page).to have_link('Project 0')
    end
  end

  describe 'filtered search' do
    before do
      focus_filtered_search
    end

    it 'allows user to search by paused and status' do
      page.within(search_bar_selector) do
        expect(page).to have_link(s_('Runners|Paused'))
        expect(page).to have_content('Status')
      end
    end
  end

  describe 'filter by tag' do
    let_it_be(:runner1) { create(:ci_runner, :group, groups: [group], description: 'runner-blue', tag_list: ['blue']) }
    let_it_be(:runner2) { create(:ci_runner, :group, groups: [group], description: 'runner-red', tag_list: ['red']) }

    it_behaves_like 'filters by tag' do
      let(:tag) { 'blue' }
      let(:found_runner) { runner1.description }
      let(:missing_runner) { runner2.description }
    end
  end
end
