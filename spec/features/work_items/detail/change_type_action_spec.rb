# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Change type action', :js, feature_category: :portfolio_management do
  include ListboxHelpers, DesignManagementTestHelpers

  let_it_be_with_reload(:user) { create(:user) }

  let_it_be(:group) { create(:group, :nested) }
  let_it_be(:project) { create(:project, :public, namespace: group, developers: user) }
  let(:issue) { create(:work_item, :issue, project: project) }
  let(:task) { create(:work_item, :task, project: project) }

  context 'for signed in user' do
    before do
      enable_design_management

      sign_in(user)
    end

    context 'when work item type is issue' do
      before do
        visit project_work_item_path(project, issue.iid)
      end

      it_behaves_like 'work items change type', 'Task', '[data-testid="issue-type-task-icon"]'

      context 'when issue has a child' do
        it 'does not allow changing the type' do
          within_testid 'work-item-tree' do
            click_button 'Add'
            click_button "Existing task"
            fill_in 'Search existing items', with: task.title
            click_button task.title
            send_keys :escape
            click_button "Add task"
            wait_for_all_requests
          end
          page.refresh
          wait_for_all_requests

          trigger_change_type('Task')

          expect(page).to have_button('Change type', disabled: true)
        end
      end
    end

    context 'when work item type is task' do
      before do
        visit project_work_item_path(project, task.iid)
      end

      it_behaves_like 'work items change type', 'Issue', '[data-testid="issue-type-issue-icon"]'

      context 'when task has a parent' do
        it 'does not allow changing the type' do
          within_testid 'work-item-parent' do
            click_button 'Edit'
            send_keys(issue.title)
            select_listbox_item(issue.title)
          end

          trigger_change_type('Issue')

          expect(page).to have_button('Change type', disabled: true)
        end
      end
    end

    context 'when there is chance of data loss' do
      let_it_be(:issue_with_data) do
        create(:issue, project: project, title: "Issue with data")
      end

      let_it_be(:design) { create(:design, :with_file, issue: issue_with_data) }

      before do
        visit project_work_item_path(project, issue_with_data.iid)
        wait_for_all_requests
      end

      it 'renders the warning about the data loss' do
        trigger_change_type('Task')

        expect(page).to have_button('Change type', disabled: false)

        within_testid('change-type-warning-message', wait: 20) do
          message = s_('Some fields are not present in %{type}. If you change type now, this information will be lost.')
          expect(page).to have_content(format(message, type: 'task'))
          expect(page).to have_content(s_('WorkItem|Designs'))
        end
      end
    end
  end

  def trigger_change_type(type)
    click_button _('More actions'), match: :first
    click_button s_('WorkItem|Change type')
    find_by_testid('work-item-change-type-select').select(type)
  end
end
