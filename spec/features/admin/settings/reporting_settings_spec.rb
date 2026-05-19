# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin updates reporting settings', :request_store, :enable_admin_mode,
  feature_category: :instance_resiliency do
  include StubENV
  include Features::SettingsHelpers

  let_it_be(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
    visit reporting_admin_application_settings_path
  end

  it 'change Spam settings' do
    within_testid('spam-settings') do
      fill_in 'reCAPTCHA site key', with: 'key'
      fill_in 'reCAPTCHA private key', with: 'key'
      find('#application_setting_recaptcha_enabled').set(true)
      find('#application_setting_login_recaptcha_protection_enabled').set(true)
      fill_in 'IP addresses per user', with: 15
      check 'Enable Spam Check via external API endpoint'
      fill_in 'URL of the external Spam Check endpoint', with: 'grpc://www.example.com/spamcheck'
      fill_in 'Spam Check API key', with: 'SPAM_CHECK_API_KEY'
    end

    expect_save_settings('spam-settings')

    expect(current_settings.recaptcha_enabled).to be true
    expect(current_settings.login_recaptcha_protection_enabled).to be true
    expect(current_settings.unique_ips_limit_per_user).to eq(15)
    expect(current_settings.spam_check_endpoint_enabled).to be true
    expect(current_settings.spam_check_endpoint_url).to eq 'grpc://www.example.com/spamcheck'
  end

  def current_settings
    ApplicationSetting.current_without_cache
  end
end
