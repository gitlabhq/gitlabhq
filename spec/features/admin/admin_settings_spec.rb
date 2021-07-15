# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin updates settings' do
  include StubENV
  include TermsHelper
  include UsageDataHelpers

  let(:admin) { create(:admin) }
  let(:dot_com?) { false }

  context 'application setting :admin_mode is enabled', :request_store do
    before do
      allow(Gitlab).to receive(:com?).and_return(dot_com?)
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      sign_in(admin)
      gitlab_enable_admin_mode_sign_in(admin)
    end

    context 'General page' do
      before do
        visit general_admin_application_settings_path
      end

      it 'change visibility settings' do
        page.within('.as-visibility-access') do
          choose "application_setting_default_project_visibility_20"
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
      end

      it 'uncheck all restricted visibility levels' do
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

      it 'modify import sources' do
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

      it 'change Visibility and Access Controls' do
        page.within('.as-visibility-access') do
          uncheck 'Project export enabled'
          click_button 'Save changes'
        end

        expect(current_settings.project_export_enabled).to be_falsey
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'change Keys settings' do
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

      it 'change Account and Limit Settings' do
        page.within('.as-account-limit') do
          uncheck 'Gravatar enabled'
          click_button 'Save changes'
        end

        expect(current_settings.gravatar_enabled).to be_falsey
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'change Maximum import size' do
        page.within('.as-account-limit') do
          fill_in 'Maximum import size (MB)', with: 15
          click_button 'Save changes'
        end

        expect(current_settings.max_import_size).to eq 15
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'change New users set to external', :js do
        user_internal_regex = find('#application_setting_user_default_internal_regex', visible: :all)

        expect(user_internal_regex).to be_readonly
        expect(user_internal_regex['placeholder']).to eq 'To define internal users, first enable new users set to external'

        check 'application_setting_user_default_external'

        expect(user_internal_regex).not_to be_readonly
        expect(user_internal_regex['placeholder']).to eq 'Regex pattern'
      end

      context 'Dormant users' do
        context 'when Gitlab.com' do
          let(:dot_com?) { true }

          it 'does not expose the setting' do
            expect(page).to have_no_selector('#application_setting_deactivate_dormant_users')
          end
        end

        context 'when not Gitlab.com' do
          let(:dot_com?) { false }

          it 'change Dormant users' do
            expect(page).to have_unchecked_field('Deactivate dormant users after 90 days of inactivity')
            expect(current_settings.deactivate_dormant_users).to be_falsey

            page.within('.as-account-limit') do
              check 'application_setting_deactivate_dormant_users'
              click_button 'Save changes'
            end

            expect(page).to have_content "Application settings saved successfully"

            page.refresh

            expect(current_settings.deactivate_dormant_users).to be_truthy
            expect(page).to have_checked_field('Deactivate dormant users after 90 days of inactivity')
          end
        end
      end

      context 'Change Sign-up restrictions' do
        context 'Require Admin approval for new signup setting' do
          it 'changes the setting', :js do
            page.within('.as-signup') do
              check 'Require admin approval for new sign-ups'
              click_button 'Save changes'
            end

            expect(current_settings.require_admin_approval_after_user_signup).to be_truthy
            expect(page).to have_content "Application settings saved successfully"
          end
        end
      end

      it 'change Sign-in restrictions' do
        page.within('.as-signin') do
          fill_in 'Home page URL', with: 'https://about.gitlab.com/'
          click_button 'Save changes'
        end

        expect(current_settings.home_page_url).to eq "https://about.gitlab.com/"
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'terms of Service' do
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

      it 'modify oauth providers' do
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

      it 'oauth providers do not raise validation errors when saving unrelated changes' do
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

      it 'configure web terminal' do
        page.within('.as-terminal') do
          fill_in 'Max session time', with: 15
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.terminal_max_session_time).to eq(15)
      end

      context 'Configure Gitpod' do
        it 'changes gitpod settings' do
          page.within('#js-gitpod-settings') do
            check 'Enable Gitpod integration'
            fill_in 'Gitpod URL', with: 'https://gitpod.test/'
            click_button 'Save changes'
          end

          expect(page).to have_content 'Application settings saved successfully'
          expect(current_settings.gitpod_url).to eq('https://gitpod.test/')
          expect(current_settings.gitpod_enabled).to be(true)
        end
      end
    end

    context 'Integrations page' do
      before do
        visit general_admin_application_settings_path
      end

      it 'enable hiding third party offers' do
        page.within('.as-third-party-offers') do
          check 'Do not display offers from third parties'
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.hide_third_party_offers).to be true
      end

      it 'enabling Mailgun events', :aggregate_failures do
        page.within('.as-mailgun') do
          check 'Enable Mailgun event receiver'
          fill_in 'Mailgun HTTP webhook signing key', with: 'MAILGUN_SIGNING_KEY'
          click_button 'Save changes'
        end

        expect(page).to have_content 'Application settings saved successfully'
        expect(current_settings.mailgun_events_enabled).to be true
        expect(current_settings.mailgun_signing_key).to eq 'MAILGUN_SIGNING_KEY'
      end
    end

    context 'Integration page', :js do
      before do
        visit integrations_admin_application_settings_path
      end

      it 'shows integrations table' do
        expect(page).to have_selector '[data-testid="inactive-integrations-table"]'
      end
    end

    context 'CI/CD page' do
      it 'change CI/CD settings' do
        visit ci_cd_admin_application_settings_path

        page.within('.as-ci-cd') do
          check 'Default to Auto DevOps pipeline for all projects'
          fill_in 'application_setting_auto_devops_domain', with: 'domain.com'
          uncheck 'Keep the latest artifacts for all jobs in the latest successful pipelines'
          click_button 'Save changes'
        end

        expect(current_settings.auto_devops_enabled?).to be true
        expect(current_settings.auto_devops_domain).to eq('domain.com')
        expect(current_settings.keep_latest_artifact).to be false
        expect(page).to have_content "Application settings saved successfully"
      end

      context 'Runner Registration' do
        context 'when feature is enabled' do
          before do
            stub_feature_flags(runner_registration_control: true)
          end

          it 'allows admins to control who has access to register runners' do
            visit ci_cd_admin_application_settings_path

            expect(current_settings.valid_runner_registrars).to eq(ApplicationSetting::VALID_RUNNER_REGISTRAR_TYPES)

            page.within('.as-runner') do
              find_all('.form-check-input').each(&:click)

              click_button 'Save changes'
            end

            expect(current_settings.valid_runner_registrars).to eq([])
            expect(page).to have_content "Application settings saved successfully"
          end
        end

        context 'when feature is disabled' do
          before do
            stub_feature_flags(runner_registration_control: false)
          end

          it 'does not allow admins to control who has access to register runners' do
            visit ci_cd_admin_application_settings_path

            expect(current_settings.valid_runner_registrars).to eq(ApplicationSetting::VALID_RUNNER_REGISTRAR_TYPES)

            expect(page).not_to have_css('.as-runner')
          end
        end
      end

      context 'Container Registry' do
        let(:feature_flag_enabled) { true }
        let(:client_support) { true }
        let(:settings_titles) do
          {
            container_registry_delete_tags_service_timeout: 'Container Registry delete tags service execution timeout',
            container_registry_expiration_policies_worker_capacity: 'Cleanup policy maximum workers running concurrently',
            container_registry_cleanup_tags_service_max_list_size: 'Cleanup policy maximum number of tags to be deleted'
          }
        end

        before do
          stub_container_registry_config(enabled: true)
          stub_feature_flags(container_registry_expiration_policies_throttling: feature_flag_enabled)
          allow(ContainerRegistry::Client).to receive(:supports_tag_delete?).and_return(client_support)
        end

        shared_examples 'not having container registry setting' do |registry_setting|
          it "lacks the container setting #{registry_setting}" do
            visit ci_cd_admin_application_settings_path

            expect(page).not_to have_content(settings_titles[registry_setting])
          end
        end

        %i[container_registry_delete_tags_service_timeout container_registry_expiration_policies_worker_capacity container_registry_cleanup_tags_service_max_list_size].each do |setting|
          context "for container registry setting #{setting}" do
            context 'with feature flag enabled' do
              context 'with client supporting tag delete' do
                it 'changes the setting' do
                  visit ci_cd_admin_application_settings_path

                  page.within('.as-registry') do
                    fill_in "application_setting_#{setting}", with: 400
                    click_button 'Save changes'
                  end

                  expect(current_settings.public_send(setting)).to eq(400)
                  expect(page).to have_content "Application settings saved successfully"
                end
              end

              context 'with client not supporting tag delete' do
                let(:client_support) { false }

                it_behaves_like 'not having container registry setting', setting
              end
            end

            context 'with feature flag disabled' do
              let(:feature_flag_enabled) { false }

              it_behaves_like 'not having container registry setting', setting
            end
          end
        end
      end
    end

    context 'Repository page' do
      it 'change Repository storage settings' do
        visit repository_admin_application_settings_path

        page.within('.as-repository-storage') do
          fill_in 'application_setting_repository_storages_weighted_default', with: 50
          click_button 'Save changes'
        end

        expect(current_settings.repository_storages_weighted).to eq('default' => 50)
      end

      it 'still saves when settings are outdated' do
        current_settings.update_attribute :repository_storages_weighted, { 'default' => 100, 'outdated' => 100 }

        visit repository_admin_application_settings_path

        page.within('.as-repository-storage') do
          fill_in 'application_setting_repository_storages_weighted_default', with: 50
          click_button 'Save changes'
        end

        expect(current_settings.repository_storages_weighted).to eq('default' => 50)
      end
    end

    context 'Reporting page' do
      it 'change Spam settings' do
        visit reporting_admin_application_settings_path

        page.within('.as-spam') do
          fill_in 'reCAPTCHA Site Key', with: 'key'
          fill_in 'reCAPTCHA Private Key', with: 'key'
          check 'Enable reCAPTCHA'
          check 'Enable reCAPTCHA for login'
          fill_in 'IPs per user', with: 15
          check 'Enable Spam Check via external API endpoint'
          fill_in 'URL of the external Spam Check endpoint', with: 'grpc://www.example.com/spamcheck'
          fill_in 'Spam Check API Key', with: 'SPAM_CHECK_API_KEY'
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.recaptcha_enabled).to be true
        expect(current_settings.login_recaptcha_protection_enabled).to be true
        expect(current_settings.unique_ips_limit_per_user).to eq(15)
        expect(current_settings.spam_check_endpoint_enabled).to be true
        expect(current_settings.spam_check_endpoint_url).to eq 'grpc://www.example.com/spamcheck'
      end
    end

    context 'Metrics and profiling page' do
      before do
        visit metrics_and_profiling_admin_application_settings_path
      end

      it 'change Prometheus settings' do
        page.within('.as-prometheus') do
          check 'Enable Prometheus Metrics'
          click_button 'Save changes'
        end

        expect(current_settings.prometheus_metrics_enabled?).to be true
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'change Performance bar settings' do
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
        stub_usage_data_connections

        page.within('#js-usage-settings') do
          expected_payload_content = /(?=.*"uuid")(?=.*"hostname")/m

          expect(page).not_to have_content expected_payload_content

          click_button('Preview payload')

          wait_for_requests

          expect(page).to have_selector '.js-service-ping-payload'
          expect(page).to have_button 'Hide payload'
          expect(page).to have_content expected_payload_content
        end
      end
    end

    context 'Network page' do
      it 'changes Outbound requests settings' do
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

      it 'changes Issues rate limits settings' do
        visit network_admin_application_settings_path

        page.within('.as-issue-limits') do
          fill_in 'Max requests per minute per user', with: 0
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

      it 'change Help page' do
        stub_feature_flags(help_page_documentation_redirect: true)

        new_support_url = 'http://example.com/help'
        new_documentation_url = 'https://docs.gitlab.com'

        page.within('.as-help-page') do
          fill_in 'Additional text to show on the Help page', with: 'Example text'
          check 'Hide marketing-related entries from the Help page.'
          fill_in 'Support page URL', with: new_support_url
          fill_in 'Documentation pages URL', with: new_documentation_url
          click_button 'Save changes'
        end

        expect(current_settings.help_page_text).to eq "Example text"
        expect(current_settings.help_page_hide_commercial_content).to be_truthy
        expect(current_settings.help_page_support_url).to eq new_support_url
        expect(current_settings.help_page_documentation_base_url).to eq new_documentation_url
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'change Pages settings' do
        page.within('.as-pages') do
          fill_in 'Maximum size of pages (MB)', with: 15
          check 'Require users to prove ownership of custom domains'
          click_button 'Save changes'
        end

        expect(current_settings.max_pages_size).to eq 15
        expect(current_settings.pages_domain_verification_enabled?).to be_truthy
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'change Real-time features settings' do
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

      it "change Pages Let's Encrypt settings" do
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
      it 'shows default help links in nav' do
        default_support_url = "https://#{ApplicationHelper.promo_host}/getting-help/"

        visit root_dashboard_path

        find('.header-help-dropdown-toggle').click

        page.within '.header-help' do
          expect(page).to have_link(text: 'Help', href: help_path)
          expect(page).to have_link(text: 'Support', href: default_support_url)
        end
      end

      it 'shows custom support url in nav when set' do
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

  context 'application setting :admin_mode is disabled' do
    before do
      stub_application_setting(admin_mode: false)

      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')

      sign_in(admin)
      visit general_admin_application_settings_path
    end

    it 'loads admin settings page without redirect for reauthentication' do
      expect(current_path).to eq general_admin_application_settings_path
    end
  end

  def check_all_events
    page.check('Active')
    page.check('Push')
    page.check('Issue')
    page.check('Confidential Issue')
    page.check('Merge Request')
    page.check('Note')
    page.check('Confidential Note')
    page.check('Tag Push')
    page.check('Pipeline')
    page.check('Wiki Page')
    page.check('Deployment')
  end

  def current_settings
    ApplicationSetting.current_without_cache
  end
end
