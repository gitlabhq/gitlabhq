# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin Health Check", :feature do
  include StubENV
  let_it_be(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
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
end
