# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work items bulk editing', :js, feature_category: :team_planning do
  include WorkItemsHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:bug_label) { create(:label, project: project, title: 'bug') }
  let_it_be(:feature_label) { create(:label, project: project, title: 'feature') }
  let_it_be(:frontend_label) { create(:label, project: project, title: 'frontend') }
  let_it_be(:wontfix_label) { create(:label, project: project, title: 'wontfix') }
  let_it_be(:issue) { create(:work_item, :issue, project: project, title: "Issue without label") }
  let_it_be(:task) { create(:work_item, :task, project: project, title: "Task without label") }
  let_it_be(:task_2) { create(:work_item, :task, project: project, title: "Task 2") }
  let_it_be(:incident) { create(:incident, project: project, title: "Incident 1") }
  let_it_be(:issue_with_label) do
    create(:work_item, :issue, project: project, title: "Issue with label", labels: [frontend_label])
  end

  let_it_be(:issue_with_multiple_labels) do
    create(:work_item, :issue, project: project, title: "Issue with multiple labels",
      labels: [frontend_label, wontfix_label, feature_label])
  end

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in user
    stub_feature_flags(work_items_saved_views: false)
  end

  context 'when user is signed in' do
    context 'when bulk editing labels on project work items' do
      before do
        visit project_work_items_path(project)
        click_bulk_edit
      end

      it_behaves_like 'when user bulk assigns labels' do
        let(:work_item) { issue }
        let(:work_item_with_label) { issue_with_label }
        let(:work_item_2) { task }
      end

      it_behaves_like 'when user bulk unassigns labels' do
        let(:work_item_with_label) { issue_with_label }
        let(:work_item_with_multiple_labels) { issue_with_multiple_labels }
      end

      it_behaves_like 'when user bulk assigns and unassigns labels simultaneously' do
        let(:work_item) { issue }
        let(:work_item_with_label) { issue_with_label }
      end
    end

    context 'when bulk editing labels on project issues list' do
      before do
        visit project_issues_path(project)
        wait_for_requests
        # clear the type filter as we will also update task
        click_button 'Clear'
        click_bulk_edit
      end

      it_behaves_like 'when user bulk assigns labels' do
        let(:work_item) { issue }
        let(:work_item_with_label) { issue_with_label }
      end

      it_behaves_like 'when user bulk assign labels on mixed work item types' do
        let(:work_item) { issue }
        let(:work_item_2) { task }
      end

      it_behaves_like 'when user bulk unassigns labels' do
        let(:work_item_with_label) { issue_with_label }
        let(:work_item_with_multiple_labels) { issue_with_multiple_labels }
      end

      it_behaves_like 'when user bulk assigns and unassigns labels simultaneously' do
        let(:work_item) { issue }
        let(:work_item_with_label) { issue_with_label }
      end
    end

    context 'when bulk editing parent on project issue list' do
      before do
        allow(Gitlab::QueryLimiting).to receive(:threshold).and_return(137)

        visit project_issues_path(project)
        # clear the type filter as we will also update task
        click_button 'Clear'
        click_bulk_edit
      end

      it_behaves_like 'when user bulk assigns parent' do
        let(:child_work_item) { task }
        let(:parent_work_item) { issue }
        let(:child_work_item_2) { task_2 }
      end

      context 'when unassigning a parent' do
        before do
          create(:parent_link, work_item_parent: issue, work_item: task)
          create(:parent_link, work_item_parent: issue, work_item: task_2)
          page.refresh

          click_bulk_edit
        end

        it_behaves_like 'when user bulk unassigns parent' do
          let(:child_work_item) { task }
          let(:parent_work_item) { issue }
          let(:child_work_item_2) { task_2 }
        end
      end

      it_behaves_like 'when parent bulk edit shows no available items' do
        let(:incompatible_work_item) { incident }
        let(:incompatible_work_item_1) { issue }
        let(:incompatible_work_item_2) { task }
      end

      it_behaves_like 'when parent bulk edit fetches correct work items' do
        let(:child_work_item) { task }
        let(:parent_work_item) { issue }
        let(:incident_work_item) { incident }
      end
    end
  end
end
