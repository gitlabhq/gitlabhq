require 'spec_helper'

describe 'Service Desk Issue Tracker' do
  let(:project) { create(:project, :private, service_desk_enabled: true) }
  let(:user) { create(:user) }

  before do
    allow(License).to receive(:feature_available?).and_call_original
    allow(License).to receive(:feature_available?).with(:service_desk) { true }

    project.add_master(user)
    sign_in(user)
  end

  describe 'navigation to service desk' do
    before do
      visit project_path(project)
      find('.nav-links .shortcuts-issues').trigger('click')
      find('a[title="Service Desk"]').trigger('click')
    end

    it 'can navigate to the service desk from link in the sidebar', js: true do
      expect(page).to have_content('Use Service Desk to connect with your users')
    end
  end

  describe 'issues list', js: true do
    before do
      visit service_desk_project_issues_path(project)
    end

    context 'when service desk has not been activated' do
      describe 'service desk info content' do
        it 'displays the large info box' do
          expect(page).to have_css('.empty-state')
        end

        it 'has a link to the documentation' do
          expect(page).to have_link('Read more', href: help_page_path('user/project/service_desk'))
        end

        it 'shows a button to configure service desk' do
          expect(page).to have_link('Turn on Service Desk')
        end
      end
    end

    context 'when service desk has been activated' do
      before do
        allow(Gitlab::IncomingEmail).to receive(:enabled?) { true }
        allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }
      end

      context 'when there are no issues' do
        describe 'service desk info content' do
          it 'displays the large info box' do
            expect(page).to have_css('.empty-state')
          end

          it 'has a link to the documentation' do
            expect(page).to have_link('Read more', href: help_page_path('user/project/service_desk'))
          end

          it 'does not show a button configure service desk' do
            expect(page).not_to have_link('Turn on Service Desk')
          end

          it 'shows the service desk email address' do
            expect(page).to have_content(project.service_desk_address)
          end
        end
      end

      context 'when there are issues' do
        let(:regular_issue) { create(:issue, project: project, title: 'My invisible issue', author: user) }
        let(:service_desk_issue) { create(:issue, project: project, title: 'My visible issue', author: User.support_bot) }

        describe 'service desk info content' do
          it 'displays the small info box' do
            expect(page).to have_css('.non-empty-state')
          end

          it 'has a link to the documentation' do
            expect(page).to have_link('Read more', href: help_page_path('user/project/service_desk'))
          end

          it 'does not show a button configure service desk' do
            expect(page).not_to have_link('Turn on Service Desk')
          end

          it 'shows the service desk email address' do
            expect(page).to have_content(project.service_desk_address)
          end
        end

        describe 'issues list' do
          it 'only displays issues created by support bot' do
            expect(page).to have_selector('.issues-list .issue', count: 1)
          end
        end

        describe 'search box' do
          it 'displays the support bot author token' do
            author_token = find('.filtered-search-token .value')
            expect(author_token).to have_content('Support Bot')
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
