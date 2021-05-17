# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Service Desk Issue Tracker', :js do
  let(:project) { create(:project, :private, service_desk_enabled: true) }

  let_it_be(:user) { create(:user) }
  let_it_be(:support_bot) { User.support_bot }

  before do
    stub_feature_flags(vue_issuables_list: true)

    # The following two conditions equate to Gitlab::ServiceDesk.supported == true
    allow(Gitlab::IncomingEmail).to receive(:enabled?).and_return(true)
    allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?).and_return(true)

    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'navigation to service desk' do
    before do
      visit project_path(project)
      find('.sidebar-top-level-items .shortcuts-issues').click
      find('.sidebar-sub-level-items a', text: 'Service Desk').click
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
      context 'when there are no issues' do
        describe 'service desk info content' do
          it 'displays the large info box, documentation, and the address' do
            visit service_desk_project_issues_path(project)

            aggregate_failures do
              expect(page).to have_css('.empty-state')
              expect(page).to have_text('Use Service Desk to connect with your users')
              expect(page).to have_link('Learn more.', href: help_page_path('user/project/service_desk'))
              expect(page).not_to have_link('Enable Service Desk')
              expect(page).to have_content(project.service_desk_address)
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
                expect(page).to have_css('.empty-state')
                expect(page).to have_text('Use Service Desk to connect with your users')
                expect(page).to have_link('Learn more.', href: help_page_path('user/project/service_desk'))
                expect(page).not_to have_link('Enable Service Desk')
                expect(page).not_to have_content(project.service_desk_address)
              end
            end
          end
        end
      end

      context 'when there are issues' do
        let_it_be(:project) { create(:project, :private, service_desk_enabled: true) }
        let_it_be(:other_user) { create(:user) }
        let_it_be(:service_desk_issue) { create(:issue, project: project, author: support_bot, service_desk_reply_to: 'service.desk@example.com') }
        let_it_be(:other_user_issue) { create(:issue, project: project, author: other_user) }

        describe 'service desk info content' do
          before do
            visit service_desk_project_issues_path(project)
          end

          it 'displays the small info box, documentation, a button to configure service desk, and the address' do
            aggregate_failures do
              expect(page).to have_css('.non-empty-state')
              expect(page).to have_link('Learn more.', href: help_page_path('user/project/service_desk'))
              expect(page).not_to have_link('Enable Service Desk')
              expect(page).to have_content(project.service_desk_address)
            end
          end
        end

        describe 'issues list' do
          before do
            visit service_desk_project_issues_path(project)
          end

          it 'only displays issues created by support bot' do
            expect(page).to have_selector('.issues-list .issue', count: 1)
          end

          it 'shows service_desk_reply_to in issues list' do
            expect(page).to have_text('by service.desk@example.com via GitLab Support Bot')
          end
        end

        describe 'search box' do
          before do
            visit service_desk_project_issues_path(project)
          end

          it 'adds hidden support bot author token' do
            expect(page).to have_selector('.filtered-search-token .value', text: 'Support Bot', visible: false)
          end

          it 'support bot author token cannot be deleted' do
            find('.input-token .filtered-search').native.send_key(:backspace)
            expect(page).to have_selector('.js-visual-token', count: 1)
          end

          it 'support bot author token has been properly added' do
            within('.filtered-search-token') do
              expect(page).to have_selector('.name', count: 1, visible: false)
              expect(page).to have_selector('.operator', count: 1, visible: false)
              expect(page).to have_selector('.value-container', count: 1, visible: false)
            end
          end
        end
      end
    end

    context 'when service desk is not supported' do
      let(:project_without_service_desk) { create(:project, :private, service_desk_enabled: false) }

      before do
        allow(Gitlab::ServiceDesk).to receive(:supported?).and_return(false)
        visit service_desk_project_issues_path(project)
      end

      describe 'service desk info content' do
        context 'when user has permissions to edit project settings' do
          before do
            project_without_service_desk.add_maintainer(user)
            visit service_desk_project_issues_path(project_without_service_desk)
          end

          it 'informs user to setup incoming email to turn on support for Service Desk' do
            aggregate_failures do
              expect(page).to have_css('.empty-state')
              expect(page).to have_text('Service Desk is not supported')
              expect(page).to have_text('To enable Service Desk on this instance, an instance administrator must first set up incoming email.')
              expect(page).to have_link('Learn more.', href: help_page_path('administration/incoming_email', anchor: 'set-it-up'))
            end
          end
        end

        context 'when user does not have permission to edit project settings' do
          before do
            project_without_service_desk.add_developer(user)
            visit service_desk_project_issues_path(project_without_service_desk)
          end

          it 'informs user to contact an administrator to enable service desk' do
            expect(page).to have_css('.empty-state')
            # NOTE: here, "enabled" is not used in the sense of "ServiceDesk::Enabled?"
            expect(page).to have_text('Service Desk is not enabled')
            expect(page).to have_text('For help setting up the Service Desk for your instance, please contact an administrator.')
          end
        end
      end
    end
  end
end
