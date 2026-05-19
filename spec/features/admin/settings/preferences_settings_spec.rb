# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin updates preferences settings', :request_store, :enable_admin_mode,
  feature_category: :settings do
  include StubENV
  include Features::SettingsHelpers

  let_it_be(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
    visit preferences_admin_application_settings_path
  end

  describe 'Email page' do
    context 'when deactivation email additional text feature flag is enabled' do
      it 'shows deactivation email additional text field' do
        expect(page).to have_field 'Additional text for deactivation email'

        within_testid('email-content') do
          fill_in 'Additional text for deactivation email', with: 'So long and thanks for all the fish!'
        end

        expect_save_settings('email-content')

        expect(current_settings.deactivation_email_additional_text).to eq('So long and thanks for all the fish!')
      end
    end
  end

  it 'change Help page' do
    new_support_url = 'http://example.com/help'
    new_documentation_url = 'https://docs.gitlab.com'

    within_testid('help-page-content') do
      fill_in 'Additional text to show on the Help page', with: 'Example text'
      check 'Hide marketing-related entries from the Help page'
      fill_in 'Support page URL', with: new_support_url
      fill_in 'Documentation pages URL', with: new_documentation_url
    end

    expect_save_settings('help-page-content')

    expect(current_settings.help_page_text).to eq "Example text"
    expect(current_settings.help_page_hide_commercial_content).to be_truthy
    expect(current_settings.help_page_support_url).to eq new_support_url
    expect(current_settings.help_page_documentation_base_url).to eq new_documentation_url
  end

  it 'change Pages settings' do
    within_testid('pages-content') do
      fill_in 'Maximum size of pages (MiB)', with: 15
      check 'Require users to prove ownership of custom domains'
    end

    expect_save_settings('pages-content')

    expect(current_settings.max_pages_size).to eq 15
    expect(current_settings.pages_domain_verification_enabled?).to be_truthy
  end

  it 'change Real-time features settings' do
    within_testid('realtime-content') do
      fill_in 'Polling interval multiplier', with: 5.0
    end

    expect_save_settings('realtime-content')

    expect(current_settings.polling_interval_multiplier).to eq 5.0
  end

  it 'shows an error when validation fails' do
    within_testid('realtime-content') do
      fill_in 'Polling interval multiplier', with: -1.0
      click_button 'Save changes'
    end

    expect(current_settings.polling_interval_multiplier).not_to eq(-1.0)
    expect(page).to have_content(
      "The form contains the following error: Polling interval multiplier must be greater than or equal to 0"
    )
  end

  it "change Pages Let's Encrypt settings" do
    within_testid('pages-content') do
      fill_in "Let's Encrypt email", with: 'my@test.example.com'
      check "I have read and agree to the Let's Encrypt Terms of Service"
    end

    expect_save_settings('pages-content')

    expect(current_settings.lets_encrypt_notification_email).to eq 'my@test.example.com'
    expect(current_settings.lets_encrypt_terms_of_service_accepted).to be true
  end

  context 'for Terraform state settings' do
    it 'allows changing encryption settings' do
      expect(current_settings.terraform_state_encryption_enabled).to be true

      within '#js-terraform-limits-settings' do
        expect(page).to have_field('Turn on Terraform state encryption', type: 'checkbox')
        uncheck 'Turn on Terraform state encryption'
      end

      expect_save_settings('#js-terraform-limits-settings')

      expect(current_settings.terraform_state_encryption_enabled).to be false
    end
  end

  def current_settings
    ApplicationSetting.current_without_cache
  end
end
