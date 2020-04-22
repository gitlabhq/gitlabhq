# frozen_string_literal: true

require 'spec_helper'

describe 'Admin updates settings', :clean_gitlab_redis_shared_state, :do_not_mock_admin_mode do
  include StubENV
  include TermsHelper

  let(:admin) { create(:admin) }

  context 'feature flag :user_mode_in_session is enabled', :request_store do
    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      sign_in(admin)
      gitlab_enable_admin_mode_sign_in(admin)
    end

    context 'General page' do
      before do
        visit general_admin_application_settings_path
      end

      it 'Change visibility settings' do
        page.within('.as-visibility-access') do
          choose "application_setting_default_project_visibility_20"
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
      end

      it 'Uncheck all restricted visibility levels' do
        page.within('.as-visibility-access') do
          find('#application_setting_visibility_level_0').set(false)
          find('#application_setting_visibility_level_10').set(false)
          find('#application_setting_visibility_level_20').set(false)
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(find('#application_setting_visibility_level_0')).not_to be_checked
        expect(find('#application_setting_visibility_level_10')).not_to be_checked
        expect(find('#application_setting_visibility_level_20')).not_to be_checked
      end

      it 'Modify import sources' do
        expect(current_settings.import_sources).not_to be_empty

        page.within('.as-visibility-access') do
          Gitlab::ImportSources.options.map do |name, _|
            uncheck name
          end

          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.import_sources).to be_empty

        page.within('.as-visibility-access') do
          check "Repo by URL"
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.import_sources).to eq(['git'])
      end

      it 'Change Visibility and Access Controls' do
        page.within('.as-visibility-access') do
          uncheck 'Project export enabled'
          click_button 'Save changes'
        end

        expect(current_settings.project_export_enabled).to be_falsey
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'Change Keys settings' do
        page.within('.as-visibility-access') do
          select 'Are forbidden', from: 'RSA SSH keys'
          select 'Are allowed', from: 'DSA SSH keys'
          select 'Must be at least 384 bits', from: 'ECDSA SSH keys'
          select 'Are forbidden', from: 'ED25519 SSH keys'
          click_on 'Save changes'
        end

        forbidden = ApplicationSetting::FORBIDDEN_KEY_VALUE.to_s

        expect(page).to have_content 'Application settings saved successfully'
        expect(find_field('RSA SSH keys').value).to eq(forbidden)
        expect(find_field('DSA SSH keys').value).to eq('0')
        expect(find_field('ECDSA SSH keys').value).to eq('384')
        expect(find_field('ED25519 SSH keys').value).to eq(forbidden)
      end

      it 'Change Account and Limit Settings' do
        page.within('.as-account-limit') do
          uncheck 'Gravatar enabled'
          click_button 'Save changes'
        end

        expect(current_settings.gravatar_enabled).to be_falsey
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'Change New users set to external', :js do
        user_internal_regex = find('#application_setting_user_default_internal_regex', visible: :all)

        expect(user_internal_regex).to be_readonly
        expect(user_internal_regex['placeholder']).to eq 'To define internal users, first enable new users set to external'

        check 'application_setting_user_default_external'

        expect(user_internal_regex).not_to be_readonly
        expect(user_internal_regex['placeholder']).to eq 'Regex pattern'
      end

      it 'Change Sign-in restrictions' do
        page.within('.as-signin') do
          fill_in 'Home page URL', with: 'https://about.gitlab.com/'
          click_button 'Save changes'
        end

        expect(current_settings.home_page_url).to eq "https://about.gitlab.com/"
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'Terms of Service' do
        # Already have the admin accept terms, so they don't need to accept in this spec.
        _existing_terms = create(:term)
        accept_terms(admin)

        page.within('.as-terms') do
          check 'Require all users to accept Terms of Service and Privacy Policy when they access GitLab.'
          fill_in 'Terms of Service Agreement', with: 'Be nice!'
          click_button 'Save changes'
        end

        expect(current_settings.enforce_terms).to be(true)
        expect(current_settings.terms).to eq 'Be nice!'
        expect(page).to have_content 'Application settings saved successfully'
      end

      it 'Modify oauth providers' do
        expect(current_settings.disabled_oauth_sign_in_sources).to be_empty

        page.within('.as-signin') do
          uncheck 'Google'
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.disabled_oauth_sign_in_sources).to include('google_oauth2')

        page.within('.as-signin') do
          check "Google"
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.disabled_oauth_sign_in_sources).not_to include('google_oauth2')
      end

      it 'Oauth providers do not raise validation errors when saving unrelated changes' do
        expect(current_settings.disabled_oauth_sign_in_sources).to be_empty

        page.within('.as-signin') do
          uncheck 'Google'
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.disabled_oauth_sign_in_sources).to include('google_oauth2')

        # Remove google_oauth2 from the Omniauth strategies
        allow(Devise).to receive(:omniauth_providers).and_return([])

        # Save an unrelated setting
        page.within('.as-terms') do
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.disabled_oauth_sign_in_sources).to include('google_oauth2')
      end

      it 'Configure web terminal' do
        page.within('.as-terminal') do
          fill_in 'Max session time', with: 15
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.terminal_max_session_time).to eq(15)
      end
    end

    context 'Integrations page' do
      before do
        stub_feature_flags(instance_level_integrations: false)
        visit integrations_admin_application_settings_path
      end

      it 'Enable hiding third party offers' do
        page.within('.as-third-party-offers') do
          check 'Do not display offers from third parties within GitLab'
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.hide_third_party_offers).to be true
      end

      it 'Change Slack Notifications Service template settings' do
        first(:link, 'Service Templates').click
        click_link 'Slack notifications'
        fill_in 'Webhook', with: 'http://localhost'
        fill_in 'Username', with: 'test_user'
        fill_in 'service_push_channel', with: '#test_channel'
        page.check('Notify only broken pipelines')
        page.select 'All branches', from: 'Branches to be notified'

        check_all_events
        click_on 'Save'

        expect(page).to have_content 'Application settings saved successfully'

        click_link 'Slack notifications'

        expect(page.all('input[type=checkbox]')).to all(be_checked)
        expect(find_field('Webhook').value).to eq 'http://localhost'
        expect(find_field('Username').value).to eq 'test_user'
        expect(find('#service_push_channel').value).to eq '#test_channel'
      end

      it 'defaults Deployment events to false for chat notification template settings' do
        first(:link, 'Service Templates').click
        click_link 'Slack notifications'

        expect(find_field('Deployment')).not_to be_checked
      end
    end

    context 'Integration page', :js do
      before do
        visit integrations_admin_application_settings_path
      end

      it 'allows user to dismiss deprecation notice' do
        expect(page).to have_content('Some settings have moved')

        click_button 'Dismiss'
        wait_for_requests

        expect(page).not_to have_content('Some settings have moved')

        visit integrations_admin_application_settings_path

        expect(page).not_to have_content('Some settings have moved')
      end
    end

    context 'CI/CD page' do
      it 'Change CI/CD settings' do
        visit ci_cd_admin_application_settings_path

        page.within('.as-ci-cd') do
          check 'Default to Auto DevOps pipeline for all projects'
          fill_in 'application_setting_auto_devops_domain', with: 'domain.com'
          click_button 'Save changes'
        end

        expect(current_settings.auto_devops_enabled?).to be true
        expect(current_settings.auto_devops_domain).to eq('domain.com')
        expect(page).to have_content "Application settings saved successfully"
      end
    end

    context 'Reporting page' do
      it 'Change Spam settings' do
        visit reporting_admin_application_settings_path

        page.within('.as-spam') do
          check 'Enable reCAPTCHA'
          check 'Enable reCAPTCHA for login'
          fill_in 'reCAPTCHA Site Key', with: 'key'
          fill_in 'reCAPTCHA Private Key', with: 'key'
          fill_in 'IPs per user', with: 15
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.recaptcha_enabled).to be true
        expect(current_settings.login_recaptcha_protection_enabled).to be true
        expect(current_settings.unique_ips_limit_per_user).to eq(15)
      end
    end

    context 'Metrics and profiling page' do
      before do
        visit metrics_and_profiling_admin_application_settings_path
      end

      it 'Change Influx settings' do
        page.within('.as-influx') do
          check 'Enable InfluxDB Metrics'
          click_button 'Save changes'
        end

        expect(current_settings.metrics_enabled?).to be true
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'Change Prometheus settings' do
        page.within('.as-prometheus') do
          check 'Enable Prometheus Metrics'
          click_button 'Save changes'
        end

        expect(current_settings.prometheus_metrics_enabled?).to be true
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'Change Performance bar settings' do
        group = create(:group)

        page.within('.as-performance-bar') do
          check 'Enable access to the Performance Bar'
          fill_in 'Allowed group', with: group.path
          click_on 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(find_field('Enable access to the Performance Bar')).to be_checked
        expect(find_field('Allowed group').value).to eq group.path

        page.within('.as-performance-bar') do
          uncheck 'Enable access to the Performance Bar'
          click_on 'Save changes'
        end

        expect(page).to have_content 'Application settings saved successfully'
        expect(find_field('Enable access to the Performance Bar')).not_to be_checked
        expect(find_field('Allowed group').value).to be_nil
      end

      it 'loads usage ping payload on click', :js do
        allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)

        page.within('#js-usage-settings') do
          expected_payload_content = /(?=.*"uuid")(?=.*"hostname")/m

          expect(page).not_to have_content expected_payload_content

          click_button('Preview payload')

          wait_for_requests

          expect(page).to have_selector '.js-usage-ping-payload'
          expect(page).to have_button 'Hide payload'
          expect(page).to have_content expected_payload_content
        end
      end
    end

    context 'Network page' do
      it 'Changes Outbound requests settings' do
        visit network_admin_application_settings_path

        page.within('.as-outbound') do
          check 'Allow requests to the local network from web hooks and services'
          # Enabled by default
          uncheck 'Allow requests to the local network from system hooks'
          # Enabled by default
          uncheck 'Enforce DNS rebinding attack protection'
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.allow_local_requests_from_web_hooks_and_services).to be true
        expect(current_settings.allow_local_requests_from_system_hooks).to be false
        expect(current_settings.dns_rebinding_protection_enabled).to be false
      end

      it 'Changes Issues rate limits settings' do
        visit network_admin_application_settings_path

        page.within('.as-issue-limits') do
          fill_in 'Max requests per second per user', with: 0
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.issues_create_limit).to eq(0)
      end
    end

    context 'Preferences page' do
      before do
        visit preferences_admin_application_settings_path
      end

      it 'Change Help page' do
        new_support_url = 'http://example.com/help'

        page.within('.as-help-page') do
          fill_in 'Help page text', with: 'Example text'
          check 'Hide marketing-related entries from help'
          fill_in 'Support page URL', with: new_support_url
          click_button 'Save changes'
        end

        expect(current_settings.help_page_text).to eq "Example text"
        expect(current_settings.help_page_hide_commercial_content).to be_truthy
        expect(current_settings.help_page_support_url).to eq new_support_url
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'Change Pages settings' do
        page.within('.as-pages') do
          fill_in 'Maximum size of pages (MB)', with: 15
          check 'Require users to prove ownership of custom domains'
          click_button 'Save changes'
        end

        expect(current_settings.max_pages_size).to eq 15
        expect(current_settings.pages_domain_verification_enabled?).to be_truthy
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'Change Real-time features settings' do
        page.within('.as-realtime') do
          fill_in 'Polling interval multiplier', with: 5.0
          click_button 'Save changes'
        end

        expect(current_settings.polling_interval_multiplier).to eq 5.0
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'shows an error when validation fails' do
        page.within('.as-realtime') do
          fill_in 'Polling interval multiplier', with: -1.0
          click_button 'Save changes'
        end

        expect(current_settings.polling_interval_multiplier).not_to eq(-1.0)
        expect(page)
          .to have_content "The form contains the following error: Polling interval multiplier must be greater than or equal to 0"
      end

      it "Change Pages Let's Encrypt settings" do
        visit preferences_admin_application_settings_path
        page.within('.as-pages') do
          fill_in 'Email', with: 'my@test.example.com'
          check "I have read and agree to the Let's Encrypt Terms of Service"
          click_button 'Save changes'
        end

        expect(current_settings.lets_encrypt_notification_email).to eq 'my@test.example.com'
        expect(current_settings.lets_encrypt_terms_of_service_accepted).to eq true
      end
    end

    context 'Nav bar' do
      it 'Shows default help links in nav' do
        default_support_url = 'https://about.gitlab.com/getting-help/'

        visit root_dashboard_path

        find('.header-help-dropdown-toggle').click

        page.within '.header-help' do
          expect(page).to have_link(text: 'Help', href: help_path)
          expect(page).to have_link(text: 'Support', href: default_support_url)
        end
      end

      it 'Shows custom support url in nav when set' do
        new_support_url = 'http://example.com/help'
        stub_application_setting(help_page_support_url: new_support_url)

        visit root_dashboard_path

        find('.header-help-dropdown-toggle').click

        page.within '.header-help' do
          expect(page).to have_link(text: 'Support', href: new_support_url)
        end
      end
    end
  end

  context 'feature flag :user_mode_in_session is disabled' do
    before do
      stub_feature_flags(user_mode_in_session: false)

      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')

      sign_in(admin)
      visit general_admin_application_settings_path
    end

    it 'loads admin settings page without redirect for reauthentication' do
      expect(current_path).to eq general_admin_application_settings_path
    end
  end

  def check_all_events
    page.check('Push')
    page.check('Issue')
    page.check('Confidential issue')
    page.check('Merge request')
    page.check('Note')
    page.check('Confidential note')
    page.check('Tag push')
    page.check('Pipeline')
    page.check('Wiki page')
    page.check('Deployment')
  end

  def current_settings
    ApplicationSetting.current_without_cache
  end
end
