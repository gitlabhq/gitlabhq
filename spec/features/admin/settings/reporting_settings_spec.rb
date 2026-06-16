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

  it 'change Spam settings', :aggregate_failures do
    within_testid('spam-settings') do
      fill_field_with_new_value(_('reCAPTCHA site key'), 'key')
      fill_field_with_new_value(_('reCAPTCHA private key'), 'key')
      # 'Enable reCAPTCHA' is ambiguous with 'Enable reCAPTCHA for login.' - use field name instead.
      click_unchecked_field('application_setting_recaptcha_enabled')
      click_unchecked_field(_('Enable reCAPTCHA for login.'))
      fill_field_with_new_value(_('IP addresses per user'), '15')
      click_unchecked_field(_('Enable Spam Check via external API endpoint'))
      fill_field_with_new_value(_('URL of the external Spam Check endpoint'), 'grpc://www.example.com/spamcheck')
      fill_field_with_new_value(_('Spam Check API key'), 'SPAM_CHECK_API_KEY')

      expect_save_settings

      expect_field_value(_('reCAPTCHA site key'), 'key')
      expect_field_value(_('reCAPTCHA private key'), 'key')
      expect_field_checked('application_setting_recaptcha_enabled')
      expect_field_checked(_('Enable reCAPTCHA for login.'))
      expect_field_value(_('IP addresses per user'), '15')
      expect_field_checked(_('Enable Spam Check via external API endpoint'))
      expect_field_value(_('URL of the external Spam Check endpoint'), 'grpc://www.example.com/spamcheck')
      expect_field_value(_('Spam Check API key'), 'SPAM_CHECK_API_KEY')
    end
  end
end
