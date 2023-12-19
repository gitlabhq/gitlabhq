# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > Webhook Settings', feature_category: :webhooks do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:webhooks_path) { project_hooks_path(project) }

  before do
    sign_in(user)
    project.add_role(user, role)
  end

  context 'for developer' do
    let(:role) { :developer }

    it 'to be disallowed to view' do
      visit webhooks_path

      expect(page.status_code).to eq(404)
    end
  end

  context 'for maintainer' do
    let(:role) { :maintainer }

    context 'Webhooks' do
      let(:hook) { create(:project_hook, :all_events_enabled, enable_ssl_verification: true, project: project) }
      let(:url) { generate(:url) }

      it 'show list of webhooks' do
        hook
        visit webhooks_path

        expect(page.status_code).to eq(200)
        expect(page).to have_content(hook.url)
        expect(page).to have_content('SSL Verification: enabled')
        expect(page).to have_content('Push events')
        expect(page).to have_content('Tag push events')
        expect(page).to have_content('Issues events')
        expect(page).to have_content('Confidential issues events')
        expect(page).to have_content('Comment')
        expect(page).to have_content('Merge request events')
        expect(page).to have_content('Pipeline events')
        expect(page).to have_content('Wiki page events')
        expect(page).to have_content('Releases events')
        expect(page).to have_content('Emoji events')
      end

      it 'create webhook', :js do
        visit webhooks_path

        click_button 'Add new webhook'
        fill_in 'URL', with: url
        check 'Tag push events'
        check 'Enable SSL verification'
        check 'Job events'

        click_button 'Add webhook'

        expect(page).to have_content(url)
        expect(page).to have_content('Webhook was created')
        expect(page).to have_content('SSL Verification: enabled')
        expect(page).to have_content('Tag push events')
        expect(page).to have_content('Job events')
      end

      it 'edit existing webhook', :js do
        hook
        visit webhooks_path

        click_link 'Edit'
        fill_in 'URL', with: url
        check 'Enable SSL verification'
        click_button 'Save changes'

        expect(page).to have_content('Enable SSL verification')
        expect(page).to have_current_path(edit_project_hook_path(project, hook), ignore_query: true)
      end

      it 'test existing webhook', :js do
        WebMock.stub_request(:post, hook.url)
        visit webhooks_path

        click_button 'Test'
        click_link 'Push events'

        expect(page).to have_current_path(webhooks_path, ignore_query: true)
      end

      context 'delete existing webhook' do
        it 'from webhooks list page' do
          hook
          visit webhooks_path

          expect { click_link 'Delete' }.to change(ProjectHook, :count).by(-1)
        end

        it 'from webhook edit page' do
          hook
          visit webhooks_path
          click_link 'Edit'

          expect { click_link 'Delete' }.to change(ProjectHook, :count).by(-1)
        end
      end
    end

    context 'Webhook logs' do
      let(:hook) { create(:project_hook, project: project) }
      let(:hook_log) { create(:web_hook_log, web_hook: hook, internal_error_message: 'some error') }

      it 'show list of hook logs' do
        hook_log
        visit edit_project_hook_path(project, hook)

        expect(page).to have_content('Recent events')
        expect(page).to have_link('View details', href: hook_log.present.details_path)
      end

      it 'show hook log details' do
        hook_log
        visit edit_project_hook_path(project, hook)
        click_link 'View details'

        expect(page).to have_content("POST #{hook_log.url}")
        expect(page).to have_content(hook_log.internal_error_message)
        expect(page).to have_content('Resend Request')
      end

      it 'retry hook log' do
        WebMock.stub_request(:post, hook.url)

        hook_log
        visit edit_project_hook_path(project, hook)
        click_link 'View details'
        click_link 'Resend Request'

        expect(page).to have_current_path(edit_project_hook_path(project, hook), ignore_query: true)
      end

      it 'does not show search settings on the hook log details' do
        visit project_hook_hook_log_path(project, hook, hook_log)

        expect(page).not_to have_field(placeholder: 'Search settings', disabled: true)
      end
    end
  end
end
