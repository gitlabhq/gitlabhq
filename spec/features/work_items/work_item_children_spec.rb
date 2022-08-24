# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work item children', :js do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }

  context 'for signed in user' do
    before do
      project.add_developer(user)

      sign_in(user)

      stub_feature_flags(work_items: true)
      stub_feature_flags(work_items_hierarchy: true)

      visit project_issue_path(project, issue)

      wait_for_requests
    end

    it 'are not displayed when issue does not have work item children', :aggregate_failures do
      page.within('[data-testid="work-item-links"]') do
        expect(find('[data-testid="links-empty"]')).to have_content(_('No tasks are currently assigned.'))
        expect(page).not_to have_selector('[data-testid="add-links-form"]')
        expect(page).not_to have_selector('[data-testid="links-child"]')
      end
    end

    it 'toggles widget body', :aggregate_failures do
      page.within('[data-testid="work-item-links"]') do
        expect(page).to have_selector('[data-testid="links-body"]')

        click_button 'Collapse tasks'

        expect(page).not_to have_selector('[data-testid="links-body"]')

        click_button 'Expand tasks'

        expect(page).to have_selector('[data-testid="links-body"]')
      end
    end

    it 'toggles form', :aggregate_failures do
      page.within('[data-testid="work-item-links"]') do
        expect(page).not_to have_selector('[data-testid="add-links-form"]')

        click_button 'Add'

        expect(page).to have_selector('[data-testid="add-links-form"]')

        click_button 'Cancel'

        expect(page).not_to have_selector('[data-testid="add-links-form"]')
      end
    end

    it 'addss a child task', :aggregate_failures do
      page.within('[data-testid="work-item-links"]') do
        click_button 'Add'

        expect(page).to have_button('Create task', disabled: true)
        fill_in 'Add a title', with: 'Task 1'

        expect(page).to have_button('Create task', disabled: false)

        click_button 'Create task'

        wait_for_all_requests

        expect(find('[data-testid="links-child"]')).to have_content('Task 1')
      end
    end

    it 'removes a child task and undoing', :aggregate_failures do
      page.within('[data-testid="work-item-links"]') do
        click_button 'Add'
        fill_in 'Add a title', with: 'Task 1'
        click_button 'Create task'
        wait_for_all_requests

        expect(find('[data-testid="links-child"]')).to have_content('Task 1')
        expect(find('[data-testid="children-count"]')).to have_content('1')

        find('[data-testid="links-menu"]').click
        click_button 'Remove'

        wait_for_all_requests

        expect(page).not_to have_content('Task 1')
        expect(find('[data-testid="children-count"]')).to have_content('0')
      end

      page.within('.gl-toast') do
        expect(find('.toast-body')).to have_content(_('Child removed'))
        find('.b-toaster a', text: 'Undo').click
      end

      wait_for_all_requests

      page.within('[data-testid="work-item-links"]') do
        expect(find('[data-testid="links-child"]')).to have_content('Task 1')
        expect(find('[data-testid="children-count"]')).to have_content('1')
      end
    end
  end
end
