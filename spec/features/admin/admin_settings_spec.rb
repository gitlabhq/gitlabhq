# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin updates settings', feature_category: :shared do
  include StubENV
  include TermsHelper
  include UsageDataHelpers

  let_it_be(:admin) { create(:admin) }
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
        page.within('[data-testid="admin-visibility-access-settings"]') do
          choose "application_setting_default_project_visibility_20"
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
      end

      it 'uncheck all restricted visibility levels' do
        page.within('[data-testid="restricted-visibility-levels"]') do
          uncheck s_('VisibilityLevel|Public')
          uncheck s_('VisibilityLevel|Internal')
          uncheck s_('VisibilityLevel|Private')
        end

        page.within('[data-testid="admin-visibility-access-settings"]') do
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"

        page.within('[data-testid="restricted-visibility-levels"]') do
          expect(find_field(s_('VisibilityLevel|Public'))).not_to be_checked
          expect(find_field(s_('VisibilityLevel|Internal'))).not_to be_checked
          expect(find_field(s_('VisibilityLevel|Private'))).not_to be_checked
        end
      end

      it 'modify import sources' do
        expect(current_settings.import_sources).not_to be_empty

        page.within('[data-testid="admin-visibility-access-settings"]') do
          Gitlab::ImportSources.options.map do |name, _|
            uncheck name
          end

          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.import_sources).to be_empty

        page.within('[data-testid="admin-visibility-access-settings"]') do
          check "Repository by URL"
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.import_sources).to eq(['git'])
      end

      it 'change Visibility and Access Controls' do
        page.within('[data-testid="admin-visibility-access-settings"]') do
          page.within('[data-testid="project-export"]') do
            uncheck 'Enabled'
          end

          page.within('[data-testid="bulk-import"]') do
            check 'Enabled'
          end

          click_button 'Save changes'
        end

        expect(current_settings.project_export_enabled).to be_falsey
        expect(current_settings.bulk_import_enabled).to be(true)
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'change Keys settings' do
        page.within('[data-testid="admin-visibility-access-settings"]') do
          select 'Are forbidden', from: 'RSA SSH keys'
          select 'Are allowed', from: 'DSA SSH keys'
          select 'Must be at least 384 bits', from: 'ECDSA SSH keys'
          select 'Are forbidden', from: 'ED25519 SSH keys'
          select 'Are forbidden', from: 'ECDSA_SK SSH keys'
          select 'Are forbidden', from: 'ED25519_SK SSH keys'
          click_on 'Save changes'
        end

        forbidden = ApplicationSetting::FORBIDDEN_KEY_VALUE.to_s

        expect(page).to have_content 'Application settings saved successfully'
        expect(find_field('RSA SSH keys').value).to eq(forbidden)
        expect(find_field('DSA SSH keys').value).to eq('0')
        expect(find_field('ECDSA SSH keys').value).to eq('384')
        expect(find_field('ED25519 SSH keys').value).to eq(forbidden)
        expect(find_field('ECDSA_SK SSH keys').value).to eq(forbidden)
        expect(find_field('ED25519_SK SSH keys').value).to eq(forbidden)
      end

      it 'change Account and Limit Settings' do
        page.within(find('[data-testid="account-limit"]')) do
          uncheck 'Gravatar enabled'
          click_button 'Save changes'
        end

        expect(current_settings.gravatar_enabled).to be_falsey
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'change Maximum export size' do
        page.within(find('[data-testid="account-limit"]')) do
          fill_in 'Maximum export size (MB)', with: 25
          click_button 'Save changes'
        end

        expect(current_settings.max_export_size).to eq 25
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'change Maximum import size' do
        page.within(find('[data-testid="account-limit"]')) do
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

      context 'Dormant users', feature_category: :user_management do
        context 'when Gitlab.com' do
          let(:dot_com?) { true }

          it 'does not expose the setting section' do
            # NOTE: not_to have_content may have false positives for content
            #       that might not load instantly, so before checking that
            #       `Dormant users` subsection has _not_ loaded, we check that the
            #       `Account and limit` section _was_ loaded
            expect(page).to have_content('Account and limit')
            expect(page).not_to have_content('Dormant users')
            expect(page).not_to have_field('Deactivate dormant users after a period of inactivity')
            expect(page).not_to have_field('Days of inactivity before deactivation')
          end
        end

        context 'when not Gitlab.com' do
          let(:dot_com?) { false }

          it 'exposes the setting section' do
            expect(page).to have_content('Dormant users')
            expect(page).to have_field('Deactivate dormant users after a period of inactivity')
            expect(page).to have_field('Days of inactivity before deactivation')
          end

          it 'changes dormant users', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/408224' do
            expect(page).to have_unchecked_field('Deactivate dormant users after a period of inactivity')
            expect(current_settings.deactivate_dormant_users).to be_falsey

            page.within(find('[data-testid="account-limit"]')) do
              check 'application_setting_deactivate_dormant_users'
              click_button 'Save changes'
            end

            expect(page).to have_content "Application settings saved successfully"

            page.refresh

            expect(current_settings.deactivate_dormant_users).to be_truthy
            expect(page).to have_checked_field('Deactivate dormant users after a period of inactivity')
          end

          it 'change dormant users period', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/408224' do
            expect(page).to have_field _('Days of inactivity before deactivation')

            page.within(find('[data-testid="account-limit"]')) do
              fill_in _('application_setting_deactivate_dormant_users_period'), with: '90'
              click_button 'Save changes'
            end

            expect(page).to have_content "Application settings saved successfully"

            page.refresh

            expect(page).to have_field _('Days of inactivity before deactivation'), with: '90'
          end

          it 'displays dormant users period field validation error', :js do
            selector = '#application_setting_deactivate_dormant_users_period_error'
            expect(page).not_to have_selector(selector, visible: :visible)

            page.within(find('[data-testid="account-limit"]')) do
              check 'application_setting_deactivate_dormant_users'
              fill_in _('application_setting_deactivate_dormant_users_period'), with: '30'
              click_button 'Save changes'
            end

            expect(page).to have_selector(selector, visible: :visible)
          end

          it 'auto disables dormant users period field depending on parent checkbox', :js do
            uncheck 'application_setting_deactivate_dormant_users'
            expect(page).to have_field('application_setting_deactivate_dormant_users_period', disabled: true)

            check 'application_setting_deactivate_dormant_users'
            expect(page).to have_field('application_setting_deactivate_dormant_users_period', disabled: false)
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

        context 'Email confirmation settings' do
          it "is set to 'hard' by default" do
            expect(current_settings.email_confirmation_setting).to eq('off')
          end

          it 'changes the setting', :js do
            page.within('.as-signup') do
              choose 'Hard'
              click_button 'Save changes'
            end

            expect(current_settings.email_confirmation_setting).to eq('hard')
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
          check 'All users must accept the Terms of Service and Privacy Policy to access GitLab'
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

      context 'GitLab for Jira App settings' do
        it 'changes the setting' do
          page.within('#js-jira_connect-settings') do
            fill_in 'Jira Connect Application ID', with: '1234'
            fill_in 'Jira Connect Proxy URL', with: 'https://example.com'
            check 'Enable public key storage'
            click_button 'Save changes'
          end

          expect(current_settings.jira_connect_application_key).to eq('1234')
          expect(current_settings.jira_connect_proxy_url).to eq('https://example.com')
          expect(current_settings.jira_connect_public_key_storage_enabled).to eq(true)
          expect(page).to have_content "Application settings saved successfully"
        end
      end
    end

    context 'Integrations page' do
      before do
        visit general_admin_application_settings_path
      end

      it 'enable hiding third party offers' do
        page.within('.as-third-party-offers') do
          check 'Do not display content for customer experience improvement and offers from third parties'
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
      let_it_be(:default_plan) { create(:default_plan) }

      it 'changes CI/CD settings' do
        visit ci_cd_admin_application_settings_path

        page.within('.as-ci-cd') do
          check 'Default to Auto DevOps pipeline for all projects'
          fill_in 'application_setting_auto_devops_domain', with: 'domain.com'
          uncheck 'Keep the latest artifacts for all jobs in the latest successful pipelines'
          uncheck 'Enable pipeline suggestion banner'
          click_button 'Save changes'
        end

        expect(current_settings.auto_devops_enabled?).to be true
        expect(current_settings.auto_devops_domain).to eq('domain.com')
        expect(current_settings.keep_latest_artifact).to be false
        expect(current_settings.suggest_pipeline_enabled).to be false
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'changes CI/CD limits', :aggregate_failures do
        visit ci_cd_admin_application_settings_path

        page.within('.as-ci-cd') do
          fill_in 'plan_limits_ci_pipeline_size', with: 10
          fill_in 'plan_limits_ci_active_jobs', with: 20
          fill_in 'plan_limits_ci_active_pipelines', with: 25
          fill_in 'plan_limits_ci_project_subscriptions', with: 30
          fill_in 'plan_limits_ci_pipeline_schedules', with: 40
          fill_in 'plan_limits_ci_needs_size_limit', with: 50
          fill_in 'plan_limits_ci_registered_group_runners', with: 60
          fill_in 'plan_limits_ci_registered_project_runners', with: 70
          click_button 'Save Default limits'
        end

        limits = default_plan.reload.limits
        expect(limits.ci_pipeline_size).to eq(10)
        expect(limits.ci_active_jobs).to eq(20)
        expect(limits.ci_active_pipelines).to eq(25)
        expect(limits.ci_project_subscriptions).to eq(30)
        expect(limits.ci_pipeline_schedules).to eq(40)
        expect(limits.ci_needs_size_limit).to eq(50)
        expect(limits.ci_registered_group_runners).to eq(60)
        expect(limits.ci_registered_project_runners).to eq(70)
        expect(page).to have_content 'Application limits saved successfully'
      end

      context 'Runner Registration' do
        it 'allows admins to control who has access to register runners' do
          visit ci_cd_admin_application_settings_path

          expect(current_settings.valid_runner_registrars).to eq(ApplicationSetting::VALID_RUNNER_REGISTRAR_TYPES)

          page.within('.as-runner') do
            find_all('input[type="checkbox"]').each(&:click)

            click_button 'Save changes'
          end

          expect(current_settings.valid_runner_registrars).to eq([])
          expect(page).to have_content "Application settings saved successfully"
        end
      end

      context 'Container Registry' do
        let(:client_support) { true }
        let(:settings_titles) do
          {
            container_registry_delete_tags_service_timeout: 'Container Registry delete tags service execution timeout',
            container_registry_expiration_policies_worker_capacity: 'Cleanup policy maximum workers running concurrently',
            container_registry_cleanup_tags_service_max_list_size: 'Cleanup policy maximum number of tags to be deleted',
            container_registry_expiration_policies_caching: 'Enable cleanup policy caching'
          }
        end

        before do
          stub_container_registry_config(enabled: true)
          allow(ContainerRegistry::Client).to receive(:supports_tag_delete?).and_return(client_support)
        end

        %i[container_registry_delete_tags_service_timeout container_registry_expiration_policies_worker_capacity container_registry_cleanup_tags_service_max_list_size].each do |setting|
          context "for container registry setting #{setting}" do
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
        end

        context 'for container registry setting container_registry_expiration_policies_caching' do
          it 'updates container_registry_expiration_policies_caching' do
            old_value = current_settings.container_registry_expiration_policies_caching

            visit ci_cd_admin_application_settings_path

            page.within('.as-registry') do
              find('#application_setting_container_registry_expiration_policies_caching').click
              click_button 'Save changes'
            end

            expect(current_settings.container_registry_expiration_policies_caching).to eq(!old_value)
            expect(page).to have_content "Application settings saved successfully"
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

      context 'External storage for repository static objects' do
        it 'changes Repository external storage settings' do
          encrypted_token = Gitlab::CryptoHelper.aes256_gcm_encrypt('OldToken')
          current_settings.update_attribute :static_objects_external_storage_auth_token_encrypted, encrypted_token

          visit repository_admin_application_settings_path

          page.within('.as-repository-static-objects') do
            fill_in 'application_setting_static_objects_external_storage_url', with: 'http://example.com'
            fill_in 'application_setting_static_objects_external_storage_auth_token', with: 'Token'
            click_button 'Save changes'
          end

          expect(current_settings.static_objects_external_storage_url).to eq('http://example.com')
          expect(current_settings.static_objects_external_storage_auth_token).to eq('Token')
        end
      end
    end

    context 'Reporting page' do
      it 'change Spam settings' do
        visit reporting_admin_application_settings_path

        page.within('.as-spam') do
          fill_in 'reCAPTCHA site key', with: 'key'
          fill_in 'reCAPTCHA private key', with: 'key'
          find('#application_setting_recaptcha_enabled').set(true)
          find('#application_setting_login_recaptcha_protection_enabled').set(true)
          fill_in 'IP addresses per user', with: 15
          check 'Enable Spam Check via external API endpoint'
          fill_in 'URL of the external Spam Check endpoint', with: 'grpc://www.example.com/spamcheck'
          fill_in 'Spam Check API key', with: 'SPAM_CHECK_API_KEY'
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
          check 'Enable GitLab Prometheus metrics endpoint'
          click_button 'Save changes'
        end

        expect(current_settings.prometheus_metrics_enabled?).to be true
        expect(page).to have_content "Application settings saved successfully"
      end

      it 'change Performance bar settings' do
        group = create(:group)

        page.within('.as-performance-bar') do
          check 'Allow non-administrators access to the performance bar'
          fill_in 'Allow access to members of the following group', with: group.path
          click_on 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(find_field('Allow non-administrators access to the performance bar')).to be_checked
        expect(find_field('Allow access to members of the following group').value).to eq group.path

        page.within('.as-performance-bar') do
          uncheck 'Allow non-administrators access to the performance bar'
          click_on 'Save changes'
        end

        expect(page).to have_content 'Application settings saved successfully'
        expect(find_field('Allow non-administrators access to the performance bar')).not_to be_checked
        expect(find_field('Allow access to members of the following group').value).to be_nil
      end

      it 'loads togglable usage ping payload on click', :js do
        stub_usage_data_connections
        stub_database_flavor_check

        page.within('#js-usage-settings') do
          expected_payload_content = /(?=.*"uuid")(?=.*"hostname")/m

          expect(page).not_to have_content expected_payload_content

          click_button('Preview payload')

          wait_for_requests

          expect(page).to have_selector '.js-service-ping-payload'
          expect(page).to have_button 'Hide payload'
          expect(page).to have_content expected_payload_content

          click_button('Hide payload')

          expect(page).not_to have_content expected_payload_content
        end
      end
    end

    context 'Network page' do
      it 'changes Outbound requests settings' do
        visit network_admin_application_settings_path

        page.within('.as-outbound') do
          check 'Allow requests to the local network from webhooks and integrations'
          # Enabled by default
          uncheck 'Allow requests to the local network from system hooks'
          # Enabled by default
          uncheck 'Enforce DNS-rebinding attack protection'
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.allow_local_requests_from_web_hooks_and_services).to be true
        expect(current_settings.allow_local_requests_from_system_hooks).to be false
        expect(current_settings.dns_rebinding_protection_enabled).to be false
      end

      it 'changes User and IP Rate Limits settings' do
        visit network_admin_application_settings_path

        page.within('.as-ip-limits') do
          check 'Enable unauthenticated API request rate limit'
          fill_in 'Maximum unauthenticated API requests per rate limit period per IP', with: 100
          fill_in 'Unauthenticated API rate limit period in seconds', with: 200

          check 'Enable unauthenticated web request rate limit'
          fill_in 'Maximum unauthenticated web requests per rate limit period per IP', with: 300
          fill_in 'Unauthenticated web rate limit period in seconds', with: 400

          check 'Enable authenticated API request rate limit'
          fill_in 'Maximum authenticated API requests per rate limit period per user', with: 500
          fill_in 'Authenticated API rate limit period in seconds', with: 600

          check 'Enable authenticated web request rate limit'
          fill_in 'Maximum authenticated web requests per rate limit period per user', with: 700
          fill_in 'Authenticated web rate limit period in seconds', with: 800

          fill_in 'Plain-text response to send to clients that hit a rate limit', with: 'Custom message'

          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"

        expect(current_settings).to have_attributes(
          throttle_unauthenticated_api_enabled: true,
          throttle_unauthenticated_api_requests_per_period: 100,
          throttle_unauthenticated_api_period_in_seconds: 200,
          throttle_unauthenticated_enabled: true,
          throttle_unauthenticated_requests_per_period: 300,
          throttle_unauthenticated_period_in_seconds: 400,
          throttle_authenticated_api_enabled: true,
          throttle_authenticated_api_requests_per_period: 500,
          throttle_authenticated_api_period_in_seconds: 600,
          throttle_authenticated_web_enabled: true,
          throttle_authenticated_web_requests_per_period: 700,
          throttle_authenticated_web_period_in_seconds: 800,
          rate_limiting_response_text: 'Custom message'
        )
      end

      it 'changes Issues rate limits settings' do
        visit network_admin_application_settings_path

        page.within('.as-issue-limits') do
          fill_in 'Maximum number of requests per minute', with: 0
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.issues_create_limit).to eq(0)
      end

      it 'changes Pipelines rate limits settings' do
        visit network_admin_application_settings_path

        page.within('.as-pipeline-limits') do
          fill_in 'Maximum number of requests per minute', with: 10
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.pipeline_limit_per_project_user_sha).to eq(10)
      end

      it 'changes Users API rate limits settings' do
        visit network_admin_application_settings_path

        page.within('.as-users-api-limits') do
          fill_in 'Maximum requests per 10 minutes per user', with: 0
          fill_in 'Users to exclude from the rate limit', with: 'someone, someone_else'
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.users_get_by_id_limit).to eq(0)
        expect(current_settings.users_get_by_id_limit_allowlist).to eq(%w[someone someone_else])
      end

      it 'changes Projects API rate limits settings' do
        visit network_admin_application_settings_path

        page.within('.as-projects-api-limits') do
          fill_in 'Maximum requests per 10 minutes per IP address', with: 100
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.projects_api_rate_limit_unauthenticated).to eq(100)
      end

      shared_examples 'regular throttle rate limit settings' do
        it 'changes rate limit settings' do
          visit network_admin_application_settings_path

          page.within(".#{selector}") do
            check 'Enable unauthenticated API request rate limit'
            fill_in 'Maximum unauthenticated API requests per rate limit period per IP', with: 12
            fill_in 'Unauthenticated API rate limit period in seconds', with: 34

            check 'Enable authenticated API request rate limit'
            fill_in 'Maximum authenticated API requests per rate limit period per user', with: 56
            fill_in 'Authenticated API rate limit period in seconds', with: 78

            click_button 'Save changes'
          end

          expect(page).to have_content "Application settings saved successfully"

          expect(current_settings).to have_attributes(
            "throttle_unauthenticated_#{fragment}_enabled" => true,
            "throttle_unauthenticated_#{fragment}_requests_per_period" => 12,
            "throttle_unauthenticated_#{fragment}_period_in_seconds" => 34,
            "throttle_authenticated_#{fragment}_enabled" => true,
            "throttle_authenticated_#{fragment}_requests_per_period" => 56,
            "throttle_authenticated_#{fragment}_period_in_seconds" => 78
          )
        end
      end

      context 'Package Registry API rate limits' do
        let(:selector) { 'as-packages-limits' }
        let(:fragment) { :packages_api }

        include_examples 'regular throttle rate limit settings'
      end

      context 'Files API rate limits' do
        let(:selector) { 'as-files-limits' }
        let(:fragment) { :files_api }

        include_examples 'regular throttle rate limit settings'
      end

      context 'Deprecated API rate limits' do
        let(:selector) { 'as-deprecated-limits' }
        let(:fragment) { :deprecated_api }

        include_examples 'regular throttle rate limit settings'
      end

      it 'changes search rate limits' do
        visit network_admin_application_settings_path

        page.within('.as-search-limits') do
          fill_in 'Maximum number of requests per minute for an authenticated user', with: 98
          fill_in 'Maximum number of requests per minute for an unauthenticated IP address', with: 76
          click_button 'Save changes'
        end

        expect(page).to have_content "Application settings saved successfully"
        expect(current_settings.search_rate_limit).to eq(98)
        expect(current_settings.search_rate_limit_unauthenticated).to eq(76)
      end
    end

    context 'Preferences page' do
      before do
        stub_feature_flags(deactivation_email_additional_text: deactivation_email_additional_text_feature_flag)
        visit preferences_admin_application_settings_path
      end

      let(:deactivation_email_additional_text_feature_flag) { true }

      describe 'Email page' do
        context 'when deactivation email additional text feature flag is enabled' do
          it 'shows deactivation email additional text field' do
            expect(page).to have_field 'Additional text for deactivation email'

            page.within('.as-email') do
              fill_in 'Additional text for deactivation email', with: 'So long and thanks for all the fish!'
              click_button 'Save changes'
            end

            expect(page).to have_content 'Application settings saved successfully'
            expect(current_settings.deactivation_email_additional_text).to eq('So long and thanks for all the fish!')
          end
        end

        context 'when deactivation email additional text feature flag is disabled' do
          let(:deactivation_email_additional_text_feature_flag) { false }

          it 'does not show deactivation email additional text field' do
            expect(page).not_to have_field 'Additional text for deactivation email'
          end
        end
      end

      it 'change Help page' do
        new_support_url = 'http://example.com/help'
        new_documentation_url = 'https://docs.gitlab.com'

        page.within('.as-help-page') do
          fill_in 'Additional text to show on the Help page', with: 'Example text'
          check 'Hide marketing-related entries from the Help page'
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
          fill_in "Let's Encrypt email", with: 'my@test.example.com'
          check "I have read and agree to the Let's Encrypt Terms of Service"
          click_button 'Save changes'
        end

        expect(current_settings.lets_encrypt_notification_email).to eq 'my@test.example.com'
        expect(current_settings.lets_encrypt_terms_of_service_accepted).to eq true
      end
    end

    context 'Nav bar' do
      it 'shows default help links in nav' do
        default_support_url = "https://#{ApplicationHelper.promo_host}/get-help/"

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

    context 'Service usage data page' do
      before do
        stub_usage_data_connections
        stub_database_flavor_check
      end

      context 'when service data cached', :use_clean_rails_memory_store_caching do
        before do
          visit usage_data_admin_application_settings_path
          visit service_usage_data_admin_application_settings_path
        end

        it 'loads usage ping payload on click', :js do
          expected_payload_content = /(?=.*"uuid")(?=.*"hostname")/m

          expect(page).not_to have_content expected_payload_content

          click_button('Preview payload')

          wait_for_requests

          expect(page).to have_button 'Hide payload'
          expect(page).to have_content expected_payload_content
        end

        it 'generates usage ping payload on button click', :js do
          expect_next_instance_of(Admin::ApplicationSettingsController) do |instance|
            expect(instance).to receive(:usage_data).and_call_original
          end

          click_button('Download payload')

          wait_for_requests
        end
      end

      context 'when service data not cached' do
        it 'renders missing cache information' do
          visit service_usage_data_admin_application_settings_path

          expect(page).to have_text('Service Ping payload not found in the application cache')
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
      expect(page).to have_current_path general_admin_application_settings_path, ignore_query: true
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
