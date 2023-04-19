# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident details', :js, feature_category: :incident_management do
  include MergeRequestDiffHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:incident) { create(:incident, project: project, author: developer, description: 'description') }
  let_it_be(:issue) { create(:issue, project: project, author: developer, description: 'Issue description') }
  let_it_be(:escalation_status) { create(:incident_management_issuable_escalation_status, issue: incident) }
  let_it_be(:confidential_incident) do
    create(:incident, confidential: true, project: project, author: developer, description: 'Confidential')
  end

  before_all do
    project.add_developer(developer)
  end

  before do
    sign_in(developer)
  end

  context 'when a developer+ displays the incident' do
    before do
      visit incident_project_issues_path(project, incident)
      wait_for_requests
    end

    it 'shows correct elements on the page', :aggregate_failures do
      # shows the incident
      page.within('.issuable-details') do
        expect(find('h1')).to have_content(incident.title)
      end

      # does not show design management
      expect(page).not_to have_selector('.js-design-management')

      # shows the incident tabs
      page.within('.issuable-details') do
        incident_tabs = find('[data-testid="incident-tabs"]')

        expect(find('h1')).to have_content(incident.title)
        expect(incident_tabs).to have_content('Summary')
        expect(incident_tabs).to have_content(incident.description)
      end

      # shows the right sidebar mounted with type issue
      page.within('.layout-page') do
        sidebar = find('.right-sidebar')

        expect(page).to have_selector('.right-sidebar[data-issuable-type="issue"]')
        expect(sidebar).to have_selector('.incident-severity')
        expect(sidebar).to have_selector('.milestone')
        expect(sidebar).to have_selector('[data-testid="escalation_status_container"]')
      end
    end

    describe 'escalation status' do
      let(:sidebar) { page.find('.right-sidebar') }
      let(:widget) { sidebar.find('[data-testid="escalation_status_container"]') }
      let(:expected_dropdown_options) { escalation_status.class::STATUSES.keys.take(3).map { |key| key.to_s.titleize } }

      it 'has an interactable escalation status widget', :aggregate_failures do
        expect(current_status).to have_text(escalation_status.status_name.to_s.titleize)

        # list the available statuses
        widget.find('[data-testid="edit-button"]').click
        expect(dropdown_options.map(&:text)).to eq(expected_dropdown_options)
        expect(widget).not_to have_selector('#escalation-status-help')

        # update the status
        select_resolved(dropdown_options)
        expect(current_status).to have_text('Resolved')
        expect(escalation_status.reload).to be_resolved
      end

      private

      def dropdown_options
        widget.all('[data-testid="status-dropdown-item"]', count: 3)
      end

      def select_resolved(options)
        options.last.click
        wait_for_requests
      end

      def current_status
        widget.find('[data-testid="collapsed-content"]')
      end
    end
  end

  it 'routes the user to the incident details page when the `issue_type` is set to incident' do
    set_cookie('new-actions-popover-viewed', 'true')
    visit project_issue_path(project, issue)
    wait_for_requests

    project_path = "/#{project.full_path}"
    click_button 'Edit title and description'
    wait_for_requests

    page.within('[data-testid="issuable-form"]') do
      click_button 'Issue'
      find('[data-testid="issue-type-list-item"]', text: 'Incident').click
      click_button 'Save changes'

      wait_for_requests

      expect(page).to have_current_path("#{project_path}/-/issues/incident/#{issue.iid}")
    end
  end

  it 'routes the user to the issue details page when the `issue_type` is set to issue' do
    set_cookie('new-actions-popover-viewed', 'true')
    visit incident_project_issues_path(project, incident)
    wait_for_requests

    project_path = "/#{project.full_path}"
    click_button 'Edit title and description'
    wait_for_requests

    page.within('[data-testid="issuable-form"]') do
      click_button 'Incident'
      find('[data-testid="issue-type-list-item"]', text: 'Issue').click
      click_button 'Save changes'

      wait_for_requests

      expect(page).to have_current_path("#{project_path}/-/issues/#{incident.iid}")
    end
  end

  it 'displays the confidential badge on the sticky header when the incident is confidential' do
    visit incident_project_issues_path(project, confidential_incident)
    wait_for_requests

    sticky_header = find_by_scrolling('[data-testid=issue-sticky-header]')
    expect(sticky_header.find('[data-testid=confidential]')).to be_present
  end
end
