# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin health check", :js, feature_category: :error_budgets do
  include StubENV
  include Spec::Support::Helpers::ModalHelpers
  let_it_be(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  describe '#show' do
    before do
      visit admin_health_check_path
    end

    it 'has a health check access token' do
      page.has_text? 'Health check'
      page.has_text? 'Health information can be retrieved'

      token = Gitlab::CurrentSettings.health_check_access_token

      expect(find_by_testid('health_check_token').value).to eq token
    end

    describe 'reload access token' do
      it 'changes the access token' do
        orig_token = Gitlab::CurrentSettings.health_check_access_token
        click_link 'Reset token'
        accept_gl_confirm('Are you sure you want to reset the health check token?')

        expect(page).to have_content('New health check access token has been generated!')
        expect(find_by_testid('health_check_token').text).not_to eq orig_token
      end
    end
  end

  context 'when services are up' do
    before do
      stub_storage_settings({}) # Hide the broken storage
      visit admin_health_check_path
    end

    it 'shows healthy status' do
      expect(page).to have_content('Current status Healthy')
    end
  end

  context 'when a service is down' do
    before do
      allow(HealthCheck::Utils).to receive(:process_checks).and_return('The server is on fire')
      visit admin_health_check_path
    end

    it 'shows unhealthy status' do
      expect(page).to have_content('Current status Unhealthy')
      expect(page).to have_content('The server is on fire')
    end
  end
end
