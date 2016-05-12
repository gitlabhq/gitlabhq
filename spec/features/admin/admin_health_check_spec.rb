require 'spec_helper'

feature "Admin Health Check", feature: true do
  include WaitForAjax

  before do
    login_as :admin
  end

  describe '#show' do
    before do
      visit admin_health_check_path
    end

    it { page.has_text? 'Health Check' }
    it { page.has_text? 'Health information can be retrieved' }

    it 'has a health check access token' do
      token = current_application_settings.health_check_access_token
      expect(page).to have_content("Access token is #{token}")
      expect(page).to have_selector('#health-check-token', text: token)
    end

    describe 'reload access token', js: true do
      it 'changes the access token' do
        orig_token = current_application_settings.health_check_access_token
        click_button 'Reset health check access token'
        wait_for_ajax
        expect(find('#health-check-token').text).not_to eq orig_token
      end
    end
  end

  context 'when services are up' do
    before do
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
end
