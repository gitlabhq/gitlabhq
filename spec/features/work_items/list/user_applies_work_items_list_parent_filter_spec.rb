# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User applies parent filter', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group, developers: user) }

  let_it_be(:issue) { create(:work_item, :issue, project: project, title: 'Parent issue') }
  let_it_be(:task) { create(:work_item, :task, project: project, title: 'Child task') }
  let_it_be(:parent_link_1) { create(:parent_link, work_item: task, work_item_parent: issue) }
  let_it_be(:task_without_parent) { create(:work_item, :task, project: project, title: 'Task without parent') }

  let(:issuable_container) { '[data-testid="issuable-container"]' }

  context 'for signed in user' do
    context 'when accessing work item from project issues list' do
      before do
        stub_feature_flags(work_item_view_for_issues: true, work_item_planning_view: false)
        sign_in(user)
        visit project_issues_path(project)
      end

      it_behaves_like 'parent filter' do
        let(:parent_item) { issue }
        let(:child_item) { task }
        let(:work_item_2) { task_without_parent }
        let(:expected_count) { 3 }
      end
    end

    context 'when accessing work item from project work items list' do
      before do
        sign_in(user)
        visit project_work_items_path(project)
      end

      it_behaves_like 'parent filter' do
        let(:parent_item) { issue }
        let(:child_item) { task }
        let(:work_item_2) { task_without_parent }
        let(:expected_count) { 3 }
      end
    end
  end
end
