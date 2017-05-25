require 'spec_helper'

feature 'Integration settings', feature: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:role) { :developer }
  let(:integrations_path) { namespace_project_settings_integrations_path(project.namespace, project) }

  background do
    login_as(user)
    project.team << [user, role]
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
        expect(page).to have_content('Push Events')
        expect(page).to have_content('Tag Push Events')
        expect(page).to have_content('Issues Events')
        expect(page).to have_content('Confidential Issues Events')
        expect(page).to have_content('Note Events')
        expect(page).to have_content('Merge Requests  Events')
        expect(page).to have_content('Pipeline Events')
        expect(page).to have_content('Wiki Page Events')
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
        expect(page).to have_content('Push Events')
        expect(page).to have_content('Tag Push Events')
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

      scenario 'test existing webhook' do
        WebMock.stub_request(:post, hook.url)
        visit integrations_path

        click_link 'Test'

        expect(current_path).to eq(integrations_path)
      end

      scenario 'remove existing webhook' do
        hook
        visit integrations_path

        expect { click_link 'Remove' }.to change(ProjectHook, :count).by(-1)
      end
    end
  end
end
