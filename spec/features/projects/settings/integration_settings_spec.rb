require 'spec_helper'

feature 'Integration settings' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { :developer }
  let(:integrations_path) { project_settings_integrations_path(project) }

  background do
    sign_in(user)
    project.add_role(user, role)
  end

  context 'for developer' do
    given(:role) { :developer }

    scenario 'to be disallowed to view' do
      visit integrations_path

      expect(page.status_code).to eq(404)
    end
  end

  context 'for master' do
    given(:role) { :master }

    context 'Webhooks' do
      let(:hook) { create(:project_hook, :all_events_enabled, enable_ssl_verification: true, project: project) }
      let(:url) { generate(:url) }

      scenario 'show list of webhooks' do
        hook

        visit integrations_path

        expect(page.status_code).to eq(200)
        expect(page).to have_content(hook.url)
        expect(page).to have_content('SSL Verification: enabled')
        expect(page).to have_content('Push events')
        expect(page).to have_content('Tag push events')
        expect(page).to have_content('Issues events')
        expect(page).to have_content('Confidential issues events')
        expect(page).to have_content('Note events')
        expect(page).to have_content('Merge requests  events')
        expect(page).to have_content('Pipeline events')
        expect(page).to have_content('Wiki page events')
      end

      scenario 'create webhook' do
        visit integrations_path

        fill_in 'hook_url', with: url
        check 'Tag push events'
        check 'Enable SSL verification'
        check 'Job events'

        click_button 'Add webhook'

        expect(page).to have_content(url)
        expect(page).to have_content('SSL Verification: enabled')
        expect(page).to have_content('Push events')
        expect(page).to have_content('Tag push events')
        expect(page).to have_content('Job events')
      end

      scenario 'edit existing webhook' do
        hook
        visit integrations_path

        click_link 'Edit'
        fill_in 'hook_url', with: url
        check 'Enable SSL verification'
        click_button 'Save changes'

        expect(page).to have_content 'SSL Verification: enabled'
        expect(page).to have_content(url)
      end

      scenario 'test existing webhook', :js do
        WebMock.stub_request(:post, hook.url)
        visit integrations_path

        find('.hook-test-button.dropdown').click
        click_link 'Push events'

        expect(current_path).to eq(integrations_path)
      end

      context 'remove existing webhook' do
        scenario 'from webhooks list page' do
          hook
          visit integrations_path

          expect { click_link 'Remove' }.to change(ProjectHook, :count).by(-1)
        end

        scenario 'from webhook edit page' do
          hook
          visit integrations_path
          click_link 'Edit'

          expect { click_link 'Remove' }.to change(ProjectHook, :count).by(-1)
        end
      end
    end

    context 'Webhook logs' do
      let(:hook) { create(:project_hook, project: project) }
      let(:hook_log) { create(:web_hook_log, web_hook: hook, internal_error_message: 'some error') }

      scenario 'show list of hook logs' do
        hook_log
        visit edit_project_hook_path(project, hook)

        expect(page).to have_content('Recent Deliveries')
        expect(page).to have_content(hook_log.url)
      end

      scenario 'show hook log details' do
        hook_log
        visit edit_project_hook_path(project, hook)
        click_link 'View details'

        expect(page).to have_content("POST #{hook_log.url}")
        expect(page).to have_content(hook_log.internal_error_message)
        expect(page).to have_content('Resend Request')
      end

      scenario 'retry hook log' do
        WebMock.stub_request(:post, hook.url)

        hook_log
        visit edit_project_hook_path(project, hook)
        click_link 'View details'
        click_link 'Resend Request'

        expect(current_path).to eq(edit_project_hook_path(project, hook))
      end
    end
  end
end
