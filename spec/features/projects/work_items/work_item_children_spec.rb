# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work item children', :js, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }

  context 'for signed in user' do
    before do
      project.add_developer(user)

      sign_in(user)

      stub_feature_flags(work_items: true)

      visit project_issue_path(project, issue)

      wait_for_requests
    end

    it 'are not displayed when issue does not have work item children', :aggregate_failures do
      within_testid('work-item-links') do
        expect(find_by_testid('links-empty')).to have_content(_('No child items are currently assigned.'))
        expect(page).not_to have_selector('[data-testid="add-links-form"]')
        expect(page).not_to have_selector('[data-testid="links-child"]')
      end
    end

    it 'toggles widget body', :aggregate_failures do
      within_testid('work-item-links') do
        expect(page).to have_selector('[data-testid="widget-body"]')

        click_button 'Collapse'

        expect(page).not_to have_selector('[data-testid="widget-body"]')

        click_button 'Expand'

        expect(page).to have_selector('[data-testid="widget-body"]')
      end
    end

    it 'toggles form', :aggregate_failures do
      within_testid('work-item-links') do
        expect(page).not_to have_selector('[data-testid="add-links-form"]')

        click_button 'Add'
        click_button 'New task'

        expect(page).to have_selector('[data-testid="add-links-form"]')

        click_button 'Cancel'

        expect(page).not_to have_selector('[data-testid="add-links-form"]')
      end
    end

    it 'adds a new child task', :aggregate_failures do
      allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(104)

      within_testid('work-item-links') do
        click_button 'Add'
        click_button 'New task'

        expect(page).to have_button('Create task', disabled: true)
        fill_in 'Add a title', with: 'Task 1'

        expect(page).to have_button('Create task', disabled: false)

        click_button 'Create task'

        wait_for_all_requests

        expect(find_by_testid('links-child')).to have_content('Task 1')
      end
    end

    it 'removes a child task and undoing', :aggregate_failures do
      allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(104)
      within_testid('work-item-links') do
        click_button 'Add'
        click_button 'New task'
        fill_in 'Add a title', with: 'Task 1'
        click_button 'Create task'
        wait_for_all_requests

        expect(find_by_testid('links-child')).to have_content('Task 1')
        expect(find_by_testid('children-count')).to have_content('1')

        find_by_testid('links-child').hover
        find_by_testid('remove-work-item-link').click

        wait_for_all_requests

        expect(page).not_to have_content('Task 1')
        expect(find_by_testid('children-count')).to have_content('0')
      end

      page.within('.gl-toast') do
        expect(find('.toast-body')).to have_content(_('Child removed'))
        find('.b-toaster a', text: 'Undo').click
      end

      wait_for_all_requests

      within_testid('work-item-links') do
        expect(find_by_testid('links-child')).to have_content('Task 1')
        expect(find_by_testid('children-count')).to have_content('1')
      end
    end

    context 'with existing task' do
      let_it_be(:task) { create(:work_item, :task, project: project) }

      it 'adds an existing child task', :aggregate_failures do
        within_testid('work-item-links') do
          click_button 'Add'
          click_button 'Existing task'

          expect(page).to have_button('Add task', disabled: true)
          find_by_testid('work-item-token-select-input').set(task.title)
          wait_for_all_requests
          click_button task.title

          expect(page).to have_button('Add task', disabled: false)

          send_keys :escape

          click_button('Add task')

          wait_for_all_requests

          expect(find_by_testid('links-child')).to have_content(task.title)
        end
      end

      context 'with confidential issue' do
        let_it_be_with_reload(:issue) { create(:issue, :confidential, project: project) }
        let_it_be(:task) { create(:work_item, :confidential, :task, project: project) }

        it 'adds an existing child task', :aggregate_failures do
          within_testid('work-item-links') do
            click_button 'Add'
            click_button 'Existing task'

            expect(page).to have_button('Add task', disabled: true)
            find_by_testid('work-item-token-select-input').set(task.title)
            wait_for_all_requests
            click_button task.title

            expect(page).to have_button('Add task', disabled: false)

            send_keys :escape

            click_button('Add task')

            wait_for_all_requests

            expect(find_by_testid('links-child')).to have_content(task.title)
          end
        end
      end
    end

    context 'in work item metadata' do
      let_it_be(:label) { create(:label, title: 'Label 1', project: project) }
      let_it_be(:milestone) { create(:milestone, project: project, title: 'v1') }
      let_it_be(:task) do
        create(
          :work_item,
          :task,
          project: project,
          labels: [label],
          assignees: [user],
          milestone: milestone
        )
      end

      before do
        visit project_issue_path(project, issue)

        wait_for_requests
      end

      it 'displays labels, milestone and assignee for work item children', :aggregate_failures do
        within_testid('work-item-links') do
          click_button 'Add'
          click_button 'Existing task'

          find_by_testid('work-item-token-select-input').set(task.title)
          wait_for_all_requests
          click_button task.title

          send_keys :escape

          click_button('Add task')

          wait_for_all_requests
        end

        within_testid('links-child') do
          expect(page).to have_content(task.title)
          expect(page).to have_content(label.title)
          expect(page).to have_link(user.name)
          expect(page).to have_content(milestone.title)
        end
      end
    end
  end
end
