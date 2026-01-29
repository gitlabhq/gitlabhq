# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Service Desk Issue Tracker', :js, feature_category: :service_desk do
  let(:project) { create(:project, :private, service_desk_enabled: true) }

  let_it_be(:user) { create(:user) }

  before do
    # TODO: When removing the feature flag,
    # we won't need the tests for the issues listing page, since we'll be using
    # the work items listing page.
    stub_feature_flags(work_item_planning_view: false)
    stub_feature_flags(service_desk_list_refactor: false)

    # The following two conditions equate to ServiceDesk.supported == true
    allow(Gitlab::Email::IncomingEmail).to receive(:enabled?).and_return(true)
    allow(Gitlab::Email::IncomingEmail).to receive(:supports_wildcard?).and_return(true)

    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'navigation to service desk' do
    before do
      visit project_path(project)
      find('#menu-section-button-monitor').click
      within('#monitor') do
        click_link('Service Desk')
      end
    end

    it 'can navigate to the service desk from link in the sidebar' do
      expect(page).to have_content('Use Service Desk to connect with your users')
    end
  end

  context 'issue page' do
    let(:support_bot) { Users::Internal.in_organization(project.organization_id).support_bot }
    let(:service_desk_issue) { create(:issue, project: project, author: support_bot, service_desk_reply_to: 'service.desk@example.com') }

    it 'shows service_desk_reply_to in issue header' do
      visit project_issue_path(project, service_desk_issue)

      expect(page).to have_text('by service.desk@example.com via GitLab Support Bot')
    end
  end

  describe 'issues list' do
    context 'when service desk is supported' do
      let_it_be(:guest) { create(:user) }
      let_it_be(:other_user) { create(:user) }
      let_it_be(:project) { create(:project, :private, service_desk_enabled: true, guests: [guest]) }
      let_it_be(:support_bot) { Users::Internal.in_organization(project.organization_id).support_bot }

      context 'when there are no issues or tickets' do
        describe 'service desk empty state' do
          it 'displays the large empty state, documentation, and the email address' do
            visit service_desk_project_issues_path(project)

            aggregate_failures do
              expect(page).to have_css('[data-testid="issues-service-desk-empty-state"]')
              expect(page).to have_text('Use Service Desk to connect with your users')
              expect(page).to have_link('Learn more about Service Desk', href: help_page_path('user/project/service_desk/_index.md'))
              expect(page).not_to have_link('Enable Service Desk')
              expect(page).to have_content(::ServiceDesk::Emails.new(project).address)
            end
          end

          context 'when user does not have permission to edit project settings' do
            before do
              sign_in(guest)
              visit service_desk_project_issues_path(project)
            end

            it 'displays the large info box and the documentation link' do
              aggregate_failures do
                expect(page).to have_css('[data-testid="issues-service-desk-empty-state"]')
                expect(page).to have_text('Use Service Desk to connect with your users')
                expect(page).to have_link('Learn more about Service Desk', href: help_page_path('user/project/service_desk/_index.md'))
                expect(page).not_to have_link('Enable Service Desk')
                expect(page).not_to have_content(::ServiceDesk::Emails.new(project).address)
              end
            end
          end
        end
      end

      context 'when there are legacy issues and tickets' do
        let_it_be(:service_desk_issue) do
          create(:issue, project: project, title: 'Help from email (Legacy issue)', author: support_bot, service_desk_reply_to: 'legacy.service.desk@example.com')
        end

        let_it_be(:service_desk_ticket) do
          create(:work_item, :ticket, project: project, title: 'Help from email (Ticket)', author: support_bot, service_desk_reply_to: 'new.service.desk@example.com')
        end

        let_it_be(:other_user_issue) { create(:issue, project: project, author: other_user, title: 'Unrelated issue') }

        describe 'service desk info content' do
          before do
            visit service_desk_project_issues_path(project)
          end

          it 'displays the small info box, documentation, a button to configure service desk, and the address' do
            aggregate_failures do
              expect(page).to have_link('Learn more about Service Desk', href: help_page_path('user/project/service_desk/_index.md'))
              expect(page).not_to have_link('Enable Service Desk')
              expect(page).to have_content(::ServiceDesk::Emails.new(project).address)
            end
          end
        end

        describe 'issues list' do
          before do
            visit service_desk_project_issues_path(project)
          end

          it 'only displays issues and tickets created by support bot' do
            expect(page).to have_selector('.issues-list .issue', count: 2)
            expect(page).to have_text('Help from email (Legacy issue)')
            expect(page).to have_text('Help from email (Ticket)')
            expect(page).not_to have_text('Unrelated issue')
          end

          it 'shows service_desk_reply_to in issues list' do
            expect(page).to have_text('by legacy.service.desk@example.com via GitLab Support Bot')
            expect(page).to have_text('by new.service.desk@example.com via GitLab Support Bot')
          end
        end
      end
    end
  end
end
