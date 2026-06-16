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
        within_testid('email-content') do
          fill_field_with_new_value(_('Additional text for deactivation email'), 'So long and thanks for all the fish!')

          expect_save_settings

          expect_field_value(_('Additional text for deactivation email'), 'So long and thanks for all the fish!')
        end
      end
    end
  end

  it 'change Help page', :aggregate_failures do
    within_testid('help-page-content') do
      fill_field_with_new_value(_('Additional text to show on the Help page'), 'Example text')
      click_unchecked_field(_('Hide marketing-related entries from the Help page'))
      fill_field_with_new_value(_('Support page URL'), 'http://example.com/help')
      fill_field_with_new_value(_('Documentation pages URL'), 'https://docs.example.com')

      expect_save_settings

      expect_field_value(_('Additional text to show on the Help page'), 'Example text')
      expect_field_checked(_('Hide marketing-related entries from the Help page'))
      expect_field_value(_('Support page URL'), 'http://example.com/help')
      expect_field_value(_('Documentation pages URL'), 'https://docs.example.com')
    end
  end

  it 'change Pages settings', :aggregate_failures do
    within_testid('pages-content') do
      fill_field_with_new_value(_('Maximum size of pages (MiB)'), '15')
      fill_field_with_new_value(s_("AdminSettings|Let's Encrypt email"), 'my@test.example.com')
      click_unchecked_field("I have read and agree to the Let's Encrypt Terms of Service")

      expect_save_settings

      expect_field_value(_('Maximum size of pages (MiB)'), '15')
      expect_field_value(s_("AdminSettings|Let's Encrypt email"), 'my@test.example.com')
      expect_field_checked("I have read and agree to the Let's Encrypt Terms of Service")
    end
  end

  it 'change Real-time features settings' do
    within_testid('realtime-content') do
      fill_field_with_new_value(_('Polling interval multiplier'), '5.0')

      expect_save_settings

      expect_field_value(_('Polling interval multiplier'), '5.0')
    end
  end

  it 'shows an error when validation fails' do
    within_testid('realtime-content') do
      fill_field_with_new_value(_('Polling interval multiplier'), '-1.0')
      click_button _('Save changes')
    end

    expect_field_value(_('Polling interval multiplier'), '-1.0')
    expect(page).to have_content(
      "The form contains the following error: Polling interval multiplier must be greater than or equal to 0"
    )
  end

  context 'for Terraform state settings' do
    it 'allows changing encryption settings' do
      within('#js-terraform-limits-settings') do
        click_checked_field(s_('TerraformSettings|Turn on Terraform state encryption'))

        expect_save_settings

        expect_field_unchecked(s_('TerraformSettings|Turn on Terraform state encryption'))
      end
    end
  end
end
