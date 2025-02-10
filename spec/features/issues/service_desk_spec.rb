# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Service Desk Issue Tracker', :js, feature_category: :service_desk do
  let(:project) { create(:project, :private, service_desk_enabled: true) }

  let_it_be(:user) { create(:user) }
  let_it_be(:support_bot) { Users::Internal.support_bot }

  before do
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
    let(:service_desk_issue) { create(:issue, project: project, author: support_bot, service_desk_reply_to: 'service.desk@example.com') }

    it 'shows service_desk_reply_to in issue header' do
      visit project_issue_path(project, service_desk_issue)

      expect(page).to have_text('by service.desk@example.com via GitLab Support Bot')
    end
  end

  describe 'issues list' do
    context 'when service desk is supported' do
      before do
        stub_feature_flags(frontend_caching: true)
      end

      context 'when there are no issues' do
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
              user_2 = create(:user)

              project.add_guest(user_2)
              sign_in(user_2)
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

      context 'when there are issues' do
        let_it_be(:project) { create(:project, :private, service_desk_enabled: true) }
        let_it_be(:other_user) { create(:user) }
        let_it_be(:service_desk_issue) { create(:issue, project: project, title: 'Help from email', author: support_bot, service_desk_reply_to: 'service.desk@example.com') }
        let_it_be(:other_user_issue) { create(:issue, project: project, author: other_user) }

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

          it 'only displays issues created by support bot' do
            expect(page).to have_selector('.issues-list .issue', count: 1)
            expect(page).to have_text('Help from email')
            expect(page).not_to have_text('Unrelated issue')
          end

          it 'shows service_desk_reply_to in issues list' do
            expect(page).to have_text('by service.desk@example.com via GitLab Support Bot')
          end
        end
      end
    end

    context 'for feature flags' do
      let(:service_desk_issue) { create(:issue, project: project, author: support_bot, service_desk_reply_to: 'service.desk@example.com') }

      before do
        visit project_issue_path(project, service_desk_issue)
      end

      it 'pushes the service_desk_ticket feature flag to frontend when available' do
        stub_feature_flags(service_desk_ticket: true)

        expect(page).to have_pushed_frontend_feature_flags(serviceDeskTicket: true)
      end

      it 'does not push the service_desk_ticket feature flag to frontend when not available' do
        stub_feature_flags(service_desk_ticket: false)

        expect(page).not_to have_pushed_frontend_feature_flags(serviceDeskTicket: false)
      end
    end
  end
end
