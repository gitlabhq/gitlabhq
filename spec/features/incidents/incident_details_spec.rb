# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident details', :js, feature_category: :incident_management do
  include MergeRequestDiffHelpers

  let_it_be(:payload) do
    {
      'title' => 'Alert title',
      'start_time' => '2020-04-27T10:10:22.265949279Z',
      'custom' => {
        'alert' => {
          'fields' => %w[one two]
        }
      },
      'yet' => {
        'another' => 73
      }
    }
  end

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  let_it_be(:alert) do
    create(:alert_management_alert, project: project, payload: payload)
  end

  let_it_be(:confidential_incident) do
    create(:incident, confidential: true, project: project, author: developer, description: 'Confidential')
  end

  let_it_be_with_reload(:incident) do
    create(:incident, project: project, author: developer, description: 'description', alert_management_alert: alert)
  end

  let_it_be(:escalation_status) { create(:incident_management_issuable_escalation_status, issue: incident) }

  let_it_be_with_reload(:issue) do
    create(:issue, project: project, author: developer, description: 'Issue description')
  end

  before do
    # TODO: When removing the feature flag,
    # we won't need the tests for the issues listing page, since we'll be using
    # the work items listing page.
    stub_feature_flags(work_item_planning_view: false)
    stub_feature_flags(hide_incident_management_features: false)
    stub_feature_flags(work_item_view_for_issues: true)

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
        incident_tabs = find_by_testid('incident-tabs')

        aggregate_failures 'shows title and Summary tab' do
          expect(find('h1')).to have_content(incident.title)
          expect(incident_tabs).to have_content('Summary')
          expect(incident_tabs).to have_content(incident.description)
        end

        aggregate_failures 'shows the incident highlight bar' do
          expect(incident_tabs).to have_content('Alert events: 1')
          expect(incident_tabs).to have_content('Original alert: #1')
        end

        aggregate_failures 'when on summary tab (default tab)' do
          hidden_items = find_all('.js-issue-widgets')

          # Linked Issues/MRs + comment box + emoji block
          expect(hidden_items.count).to eq(3)
          expect(hidden_items).to all(be_visible)

          edit_button = find_all('[aria-label="Edit title and description"]')
          expect(edit_button).to all(be_visible)
        end

        aggregate_failures 'shows the Alert details tab' do
          click_link 'Alert details'

          expect(incident_tabs).to have_content('"title": "Alert title"')
          expect(incident_tabs).to have_content('"yet.another": 73')

          # does not show the linked issues and notes/comment components' do
          hidden_items = find_all('.js-issue-widgets', wait: false)

          # Linked Issues/MRs and comment box are hidden on page
          expect(hidden_items.count).to eq(0)
        end

        aggregate_failures 'does not show the linked issues and notes/comment components for the Timeline tab' do
          click_link 'Timeline'

          hidden_items = find_all('.js-issue-widgets', wait: false)

          # Linked Issues/MRs and comment box are hidden on page
          expect(hidden_items.count).to eq(0)
        end
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
      let(:widget) do
        within sidebar do
          find_by_testid('escalation_status_container')
        end
      end

      let(:expected_dropdown_options) { escalation_status.class::STATUSES.keys.take(3).map { |key| key.to_s.titleize } }

      it 'has an interactable escalation status widget', :aggregate_failures do
        expect(current_status).to have_text(escalation_status.status_name.to_s.titleize)

        # list the available statuses
        within widget do
          find_by_testid('edit-button').click
        end
        expect(dropdown_options.map(&:text)).to eq(expected_dropdown_options)
        expect(widget).not_to have_selector('#escalation-status-help')

        # update the status
        select_resolved(dropdown_options)
        expect(current_status).to have_text('Resolved')
        expect(escalation_status.reload).to be_resolved
      end

      private

      def dropdown_options
        widget.all('[data-testid="escalation-status-dropdown"] .gl-new-dropdown-item', count: 3)
      end

      def select_resolved(options)
        options.last.click
        wait_for_requests
      end

      def current_status
        within widget do
          find_by_testid('collapsed-content')
        end
      end
    end
  end

  it 'routes the user to the incident details page when the issue is converted to an incident' do
    visit project_issue_path(project, issue)

    fill_in 'Add a reply', with: '/promote_to_incident'
    click_button 'Comment'

    expect(issue.reload.issue_type).to eq('incident')
    expect(page).to have_css('h1', text: issue.title)
    expect(page).to have_testid('work-item-type-icon', text: 'Incident')
  end

  it 'routes the user to the issue details page when the `issue_type` is set to issue',
    quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/573019' do
    visit incident_project_issues_path(project, incident)
    wait_for_requests

    project_path = "/#{project.full_path}"
    click_button 'Edit title and description'
    wait_for_requests

    within_testid('issuable-form') do
      click_button 'Incident'
      find_by_testid('issue-type-list-item', text: 'Issue').click
      click_button 'Save changes'
    end

    wait_for_requests

    expect(incident.reload.issue_type).to eq('issue')
    expect(page).to have_current_path("#{project_path}/-/issues/#{incident.iid}")
    expect(page).to have_content(incident.title)
  end

  it 'displays the confidential badge on the sticky header when the incident is confidential' do
    visit incident_project_issues_path(project, confidential_incident)
    wait_for_requests

    sticky_header = find_in_page_or_panel_by_scrolling('[data-testid=issue-sticky-header]')

    page.within(sticky_header) do
      expect(page).to have_text 'Confidential'
    end
  end

  def find_in_page_or_panel_by_scrolling(selector, **options)
    if Users::ProjectStudio.enabled_for_user?(developer) # rubocop:disable RSpec/AvoidConditionalStatements -- temporary Project Studio rollout
      find_in_panel_by_scrolling(selector, **options)
    else
      find_by_scrolling(selector, **options)
    end
  end
end
