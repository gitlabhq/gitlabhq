# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Alert details', :js do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:alert) { create(:alert_management_alert, project: project, status: 'triggered', title: 'Alert') }

  before_all do
    project.add_developer(developer)
  end

  before do
    sign_in(developer)

    visit details_project_alert_management_path(project, alert)
    wait_for_requests
  end

  context 'when a developer displays the alert' do
    it 'shows the alert' do
      page.within('.alert-management-details') do
        expect(find('h2')).to have_content(alert.title)
      end
    end

    it 'shows the alert tabs' do
      page.within('.alert-management-details') do
        alert_tabs = find('[data-testid="alertDetailsTabs"]')

        expect(alert_tabs).to have_content('Alert details')
      end
    end

    it 'shows the right sidebar mounted with correct widgets' do
      page.within('.layout-page') do
        sidebar = find('.right-sidebar')

        expect(sidebar).to have_selector('.alert-status')
        expect(sidebar).to have_selector('.alert-assignees')
        expect(sidebar).to have_content('Triggered')
      end
    end

    it 'updates the alert todo button from the right sidebar' do
      expect(page).to have_selector('[data-testid="alert-todo-button"]')
      todo_button = find('[data-testid="alert-todo-button"]')

      expect(todo_button).to have_content('Add a To-Do')
      find('[data-testid="alert-todo-button"]').click
      wait_for_requests

      expect(todo_button).to have_content('Mark as done')
    end

    it 'updates the alert status from the right sidebar' do
      page.within('.alert-status') do
        alert_status = find('[data-testid="status"]')

        expect(alert_status).to have_content('Triggered')

        find('.btn-link').click
        find('.gl-new-dropdown-item', text: 'Acknowledged').click

        wait_for_requests

        expect(alert_status).to have_content('Acknowledged')
      end
    end

    it 'updates the alert assignee from the right sidebar' do
      page.within('.right-sidebar') do
        alert_assignee = find('.alert-assignees')

        expect(alert_assignee).to have_content('None - assign yourself')

        find('[data-testid="unassigned-users"]').click

        wait_for_requests

        expect(alert_assignee).to have_content('Assignee Edit John Doe')
      end
    end
  end
end
