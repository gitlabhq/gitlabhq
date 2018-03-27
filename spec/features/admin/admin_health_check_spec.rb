require 'spec_helper'

feature "Admin Health Check", :feature do
  include StubENV

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(create(:admin))
  end

  describe '#show' do
    before do
      visit admin_health_check_path
    end

    it 'has a health check access token' do
      page.has_text? 'Health Check'
      page.has_text? 'Health information can be retrieved'

      token = Gitlab::CurrentSettings.health_check_access_token

      expect(page).to have_content("Access token is #{token}")
      expect(page).to have_selector('#health-check-token', text: token)
    end

    describe 'reload access token' do
      it 'changes the access token' do
        orig_token = Gitlab::CurrentSettings.health_check_access_token
        click_button 'Reset health check access token'

        expect(page).to have_content('New health check access token has been generated!')
        expect(find('#health-check-token').text).not_to eq orig_token
      end
    end
  end

  context 'when services are up' do
    before do
      stub_storage_settings({}) # Hide the broken storage
      visit admin_health_check_path
    end

    it 'shows healthy status' do
      expect(page).to have_content('Current Status: Healthy')
    end
  end

  context 'when a service is down' do
    before do
      allow(HealthCheck::Utils).to receive(:process_checks).and_return('The server is on fire')
      visit admin_health_check_path
    end

    it 'shows unhealthy status' do
      expect(page).to have_content('Current Status: Unhealthy')
      expect(page).to have_content('The server is on fire')
    end
  end

  context 'with repository storage failures', :broken_storage do
    before do
      visit admin_health_check_path
    end

    it 'shows storage failure information' do
      hostname = Gitlab::Environment.hostname
      maximum_failures = Gitlab::CurrentSettings.current_application_settings
                           .circuitbreaker_failure_count_threshold
      number_of_failures = maximum_failures + 1

      expect(page).to have_content("broken: #{number_of_failures} failed storage access attempts:")
      expect(page).to have_content("#{hostname}: #{number_of_failures} of #{maximum_failures} failures.")
    end

    it 'allows resetting storage failures' do
      click_button 'Reset git storage health information'

      expect(page).to have_content('Git storage health information has been reset')
      expect(page).not_to have_content('failed storage access attempt')
    end
  end
end
