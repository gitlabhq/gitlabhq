# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Service Desk Ticket Tracker', :js, feature_category: :service_desk do
  let_it_be(:user) { create(:user) }

  let(:project) { create(:project, :private, service_desk_enabled: true, maintainers: [user]) }

  before do
    # TODO: When removing the feature flag,
    # we won't need the tests for the issues listing page, since we'll be using
    # the work items listing page.
    stub_feature_flags(work_item_planning_view: false)

    # The following conditions equate to ServiceDesk.supported == true
    allow(Gitlab::Email::IncomingEmail).to receive_messages(enabled?: true, supports_wildcard?: true)

    sign_in(user)
  end

  describe 'navigation to service desk list' do
    it 'navigates to the service desk list from the sidebar' do
      visit project_path(project)

      find('#menu-section-button-monitor').click
      within('#monitor') do
        click_link('Service Desk')
      end

      expect(page).to have_content('Use Service Desk to connect with your users')
    end
  end

  describe 'ticket page' do
    let(:support_bot) { Users::Internal.in_organization(project.organization_id).support_bot }
    let(:ticket) do
      create(:work_item,
        :ticket,
        project: project,
        author: support_bot,
        service_desk_reply_to: 'service.desk@example.com'
      )
    end

    it 'shows service_desk_reply_to in header' do
      visit project_issue_path(project, ticket)

      expect(page).to have_text('by service.desk@example.com via GitLab Support Bot')
    end
  end

  describe 'service desk list' do
    context 'when service desk is supported' do
      context 'when there are no tickets' do
        describe 'service desk empty state' do
          it 'displays the empty state, documentation, and the email address', :aggregate_failures do
            visit service_desk_project_issues_path(project)

            expect(page).to have_css('[data-testid="issues-service-desk-empty-state"]')
            expect(page).to have_text('Use Service Desk to connect with your users')
            expect(page).to have_link('Learn more about Service Desk',
              href: help_page_path('user/project/service_desk/_index.md'))
            expect(page).not_to have_link('Enable Service Desk')
            expect(page).to have_content(::ServiceDesk::Emails.new(project).address)
          end

          context 'when user does not have permission to edit project settings' do
            let_it_be(:guest) { create(:user) }
            let_it_be(:project_for_guest) { create(:project, :private, service_desk_enabled: true, guests: [guest]) }

            before do
              sign_in(guest)
              visit service_desk_project_issues_path(project_for_guest)
            end

            it 'displays the empty state, documentation, but not the email address', :aggregate_failures do
              expect(page).to have_css('[data-testid="issues-service-desk-empty-state"]')
              expect(page).to have_text('Use Service Desk to connect with your users')
              expect(page).to have_link('Learn more about Service Desk',
                href: help_page_path('user/project/service_desk/_index.md'))
              expect(page).not_to have_link('Enable Service Desk')
              expect(page).not_to have_content(::ServiceDesk::Emails.new(project).address)
            end
          end
        end
      end
    end
  end
end
