# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Service Desk Issue Tracker', :js do
  let(:project) { create(:project, :private, service_desk_enabled: true) }
  let(:user) { create(:user) }

  before do
    stub_feature_flags(vue_issuables_list: false)

    allow(Gitlab::IncomingEmail).to receive(:enabled?).and_return(true)
    allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?).and_return(true)

    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'navigation to service desk' do
    before do
      visit project_path(project)
      find('.sidebar-top-level-items .shortcuts-issues').click
      find('.sidebar-sub-level-items a[title="Service Desk"]').click
    end

    it 'can navigate to the service desk from link in the sidebar' do
      expect(page).to have_content('Use Service Desk to connect with your users')
    end
  end

  describe 'issues list' do
    context 'when service desk is misconfigured' do
      before do
        allow(Gitlab::ServiceDesk).to receive(:supported?).and_return(false)
        visit service_desk_project_issues_path(project)
      end

      it 'shows a message to say the configuration is incomplete' do
        expect(page).to have_css('.empty-state')
        expect(page).to have_text('Service Desk is enabled but not yet active')
        expect(page).to have_text('You must set up incoming email before it becomes active')
        expect(page).to have_link('More information', href: help_page_path('administration/incoming_email', anchor: 'set-it-up'))
      end
    end

    context 'when service desk has not been activated' do
      let(:project_without_service_desk) { create(:project, :private, service_desk_enabled: false) }

      describe 'service desk info content' do
        context 'when user has permissions to edit project settings' do
          before do
            project_without_service_desk.add_maintainer(user)
            visit service_desk_project_issues_path(project_without_service_desk)
          end

          it 'displays the large info box, documentation, and a button to configure' do
            aggregate_failures do
              expect(page).to have_css('.empty-state')
              expect(page).to have_link('Read more', href: help_page_path('user/project/service_desk'))
              expect(page).to have_link('Turn on Service Desk')
            end
          end
        end

        context 'when user does not have permission to edit project settings' do
          before do
            project_without_service_desk.add_guest(user)
            visit service_desk_project_issues_path(project_without_service_desk)
          end

          it 'does not show a button configure service desk' do
            expect(page).not_to have_link('Turn on Service Desk')
          end
        end
      end
    end

    context 'when service desk has been activated' do
      context 'when there are no issues' do
        describe 'service desk info content' do
          before do
            visit service_desk_project_issues_path(project)
          end

          it 'displays the large info box, documentation, and the address' do
            aggregate_failures do
              expect(page).to have_css('.empty-state')
              expect(page).to have_link('Read more', href: help_page_path('user/project/service_desk'))
              expect(page).not_to have_link('Turn on Service Desk')
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
                expect(page).to have_link('Read more', href: help_page_path('user/project/service_desk'))
                expect(page).not_to have_link('Turn on Service Desk')
                expect(page).not_to have_content(project.service_desk_address)
              end
            end
          end
        end
      end

      context 'when there are issues' do
        let(:support_bot) { User.support_bot }
        let(:other_user) { create(:user) }
        let!(:service_desk_issue) { create(:issue, project: project, author: support_bot) }
        let!(:other_user_issue) { create(:issue, project: project, author: other_user) }

        describe 'service desk info content' do
          before do
            visit service_desk_project_issues_path(project)
          end

          it 'displays the small info box, documentation, a button to configure service desk, and the address' do
            aggregate_failures do
              expect(page).to have_css('.non-empty-state')
              expect(page).to have_link('Read more', href: help_page_path('user/project/service_desk'))
              expect(page).not_to have_link('Turn on Service Desk')
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
        end
      end
    end
  end
end
