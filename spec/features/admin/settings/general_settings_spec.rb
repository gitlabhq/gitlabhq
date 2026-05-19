# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin updates general settings', feature_category: :settings do
  include StubENV
  include TermsHelper
  include Features::SettingsHelpers

  let_it_be(:admin) { create(:admin) }

  context 'when application setting :admin_mode is enabled', :request_store, :enable_admin_mode do
    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      sign_in(admin)
      visit general_admin_application_settings_path
    end

    context 'on General page' do
      it 'change visibility settings' do
        within_testid('admin-visibility-access-settings') do
          choose "application_setting_default_project_visibility_20"
        end

        expect_save_settings('admin-visibility-access-settings')
      end

      it 'uncheck all restricted visibility levels' do
        within_testid('restricted-visibility-levels') do
          uncheck s_('VisibilityLevel|Public')
          uncheck s_('VisibilityLevel|Internal')
          uncheck s_('VisibilityLevel|Private')
        end

        expect_save_settings('admin-visibility-access-settings')

        within_testid('restricted-visibility-levels') do
          expect(find_field(s_('VisibilityLevel|Public'))).not_to be_checked
          expect(find_field(s_('VisibilityLevel|Internal'))).not_to be_checked
          expect(find_field(s_('VisibilityLevel|Private'))).not_to be_checked
        end
      end

      it 'change deletion settings', :js do
        within_testid('admin-visibility-access-settings') do
          fill_in 'Retention period', with: 40
        end

        expect_save_settings('admin-visibility-access-settings')

        within_testid('admin-visibility-access-settings') do
          expect(find_field('Retention period').value).to eq('40')
        end
      end

      it 'modify import sources' do
        expect(current_settings.import_sources).to be_empty

        within_testid('admin-import-export-settings') do
          check "Repository by URL"
        end

        expect_save_settings('admin-import-export-settings')

        expect(current_settings.import_sources).to eq(['git'])
      end

      it 'change Visibility and Access Controls' do
        expect(current_settings.project_export_enabled).to be(true)
        expect(current_settings.bulk_import_enabled).to be(false)
        expect(current_settings.silent_admin_exports_enabled).to be(false)

        within_testid('admin-import-export-settings') do
          within_testid('project-export') do
            uncheck 'Enabled'
          end

          within_testid('bulk-import') do
            check 'Enabled'
          end

          within_testid('silent-admin-exports') do
            check 'Enabled'
          end
        end

        expect_save_settings('admin-import-export-settings')

        expect(current_settings.project_export_enabled).to be(false)
        expect(current_settings.bulk_import_enabled).to be(true)
        expect(current_settings.silent_admin_exports_enabled).to be(true)
      end

      it 'change Keys settings' do
        within_testid('admin-visibility-access-settings') do
          select 'Are forbidden', from: 'RSA SSH keys'
          select 'Are allowed', from: 'DSA SSH keys'
          select 'Must be at least 384 bits', from: 'ECDSA SSH keys'
          select 'Are forbidden', from: 'ED25519 SSH keys'
          select 'Are forbidden', from: 'ECDSA_SK SSH keys'
          select 'Are forbidden', from: 'ED25519_SK SSH keys'
        end

        expect_save_settings('admin-visibility-access-settings')

        forbidden = ApplicationSetting::FORBIDDEN_KEY_VALUE.to_s

        expect(find_field('RSA SSH keys').value).to eq(forbidden)
        expect(find_field('DSA SSH keys').value).to eq('0')
        expect(find_field('ECDSA SSH keys').value).to eq('384')
        expect(find_field('ED25519 SSH keys').value).to eq(forbidden)
        expect(find_field('ECDSA_SK SSH keys').value).to eq(forbidden)
        expect(find_field('ED25519_SK SSH keys').value).to eq(forbidden)
      end

      it 'change Account and Limit Settings' do
        within_testid('account-and-limit-settings-content') do
          uncheck 'Gravatar enabled'
        end

        expect_save_settings('account-and-limit-settings-content')

        expect(current_settings.gravatar_enabled).to be_falsey
      end

      it 'change Maximum export size' do
        within_testid('admin-import-export-settings') do
          fill_in 'Maximum export size (MiB)', with: 25
        end

        expect_save_settings('admin-import-export-settings')

        expect(current_settings.max_export_size).to eq 25
      end

      it 'change Maximum import size' do
        within_testid('admin-import-export-settings') do
          fill_in 'Maximum import size (MiB)', with: 15
        end

        expect_save_settings('admin-import-export-settings')

        expect(current_settings.max_import_size).to eq 15
      end

      it 'change Diff limits settings' do
        within_testid('diff-limits-settings') do
          fill_in 'Maximum diff versions per merge request', with: 500
          fill_in 'Maximum diff commits per merge request', with: 500_000
          click_button 'Save changes'
        end

        expect(page).to have_content 'Application settings saved successfully'
        expect(current_settings.diff_max_versions).to eq 500
        expect(current_settings.diff_max_commits).to eq 500_000
      end

      it 'change New users set to external', :js,
        quarantine: { issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/20325',
                      type: 'flaky' } do
        user_internal_regex = find('#application_setting_user_default_internal_regex', visible: :all)

        expect(user_internal_regex).to be_readonly
        expect(user_internal_regex['placeholder']).to eq 'Regex pattern. To use, select external by default setting'

        check 'application_setting_user_default_external'

        expect(user_internal_regex).not_to be_readonly
        expect(user_internal_regex['placeholder']).to eq 'Regex pattern'
      end

      context 'for Dormant users', feature_category: :user_management do
        context 'when Gitlab.com', :saas do
          it 'does not expose the setting section',
            quarantine: { issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/20325',
                          type: 'flaky' } do
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
          it 'exposes the setting section',
            quarantine: { issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/20325',
                          type: 'flaky' } do
            expect(page).to have_content('Dormant users')
            expect(page).to have_field('Deactivate dormant users after a period of inactivity')
            expect(page).to have_field('Days of inactivity before deactivation')
          end

          it 'changes dormant users', :js do
            expect(page).to have_unchecked_field(_('Deactivate dormant users after a period of inactivity'))
            expect(current_settings.deactivate_dormant_users).to be_falsey

            within_testid('account-and-limit-settings-content') do
              check _('Deactivate dormant users after a period of inactivity')
            end

            expect_save_settings('account-and-limit-settings-content')

            page.refresh

            expect(page).to have_checked_field(_('Deactivate dormant users after a period of inactivity'))
            expect(current_settings.deactivate_dormant_users).to be_truthy
          end

          it 'change dormant users period', :js do
            expect(page).to have_field(_('Days of inactivity before deactivation'), disabled: true)

            within_testid('account-and-limit-settings-content') do
              check _('Deactivate dormant users after a period of inactivity')
              fill_in _('Days of inactivity before deactivation'), with: '180'
            end

            expect_save_settings('account-and-limit-settings-content')

            page.refresh

            expect(page).to have_field(_('Days of inactivity before deactivation'), disabled: false, with: '180')
          end

          it 'displays dormant users period field validation error', :js,
            quarantine: { issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/20325',
                          type: 'flaky' } do
            selector = '#application_setting_deactivate_dormant_users_period_error'
            expect(page).not_to have_selector(selector, visible: :visible)

            within_testid('account-and-limit-settings-content') do
              check 'application_setting_deactivate_dormant_users'
              fill_in _('application_setting_deactivate_dormant_users_period'), with: '30'
              click_button 'Save changes'
            end

            expect(page).to have_selector(selector, visible: :visible)
          end

          it 'auto disables dormant users period field depending on parent checkbox', :js,
            quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/449030' do
            uncheck 'application_setting_deactivate_dormant_users'
            expect(page).to have_field('application_setting_deactivate_dormant_users_period', disabled: true)

            check 'application_setting_deactivate_dormant_users'
            expect(page).to have_field('application_setting_deactivate_dormant_users_period', disabled: false)
          end
        end
      end

      context 'when changing sign-up restrictions' do
        context 'for Require Admin approval for new signup setting' do
          it 'changes the setting', :js do
            within_testid('sign-up-restrictions-settings-content') do
              check 'Require admin approval for new user accounts'
            end

            expect_save_settings('sign-up-restrictions-settings-content')

            expect(current_settings.require_admin_approval_after_user_signup).to be_truthy
          end
        end

        context 'for email confirmation settings' do
          it "is set to 'hard' by default" do
            expect(current_settings.email_confirmation_setting).to eq('off')
          end

          it 'changes the setting', :js do
            within_testid('sign-up-restrictions-settings-content') do
              choose 'Hard'
            end

            expect_save_settings('sign-up-restrictions-settings-content')

            expect(current_settings.email_confirmation_setting).to eq('hard')
          end
        end
      end

      it 'change Sign-in restrictions' do
        within_testid('signin-settings') do
          fill_in 'Home page URL', with: 'https://about.gitlab.com/'
        end

        expect_save_settings('signin-settings')

        expect(current_settings.home_page_url).to eq "https://about.gitlab.com/"
      end

      it 'terms of Service', :js do
        # Already have the admin accept terms, so they don't need to accept in this spec.
        _existing_terms = create(:term)
        accept_terms(admin)

        within_testid('terms-settings') do
          check 'All users must accept the Terms of Service and Privacy Policy to access GitLab'
          fill_in 'Terms of Service Agreement', with: 'Be nice!'
          click_button 'Save changes'
        end

        within_testid('terms-content') do
          expect(page).to have_content('Be nice!')
        end

        click_button 'Accept terms'

        expect(page).to have_current_path(general_admin_application_settings_path, ignore_query: true)
      end

      context 'for project and group access tokens settings' do
        it 'changes inactive_resource_access_tokens_delete_after_days' do
          expect(current_settings.inactive_resource_access_tokens_delete_after_days).to eq 30

          within_testid('account-and-limit-settings-content') do
            fill_in 'Inactive project and group access token retention period', with: '42'
          end

          expect_save_settings('account-and-limit-settings-content')

          expect(current_settings.inactive_resource_access_tokens_delete_after_days).to eq 42
        end
      end

      it 'modify oauth providers' do
        expect(current_settings.disabled_oauth_sign_in_sources).to be_empty

        within_testid('signin-settings') do
          uncheck 'Google'
        end

        expect_save_settings('signin-settings')

        expect(current_settings.disabled_oauth_sign_in_sources).to include('google_oauth2')
      end

      it 'oauth providers do not raise validation errors when saving unrelated changes' do
        expect(current_settings.disabled_oauth_sign_in_sources).to be_empty

        within_testid('signin-settings') do
          uncheck 'Google'
        end

        expect_save_settings('signin-settings', refresh: true)

        expect(current_settings.disabled_oauth_sign_in_sources).to include('google_oauth2')

        # Remove google_oauth2 from the Omniauth strategies
        allow(Devise).to receive(:omniauth_providers).and_return([])

        # Save an unrelated setting
        expect_save_settings('terms-settings')

        expect(current_settings.disabled_oauth_sign_in_sources).to include('google_oauth2')
      end

      it 'configure web terminal' do
        within_testid('terminal-settings') do
          fill_in 'Max session time', with: 15
        end

        expect_save_settings('terminal-settings')

        expect(current_settings.terminal_max_session_time).to eq(15)
      end

      context 'when configuring Ona' do
        it 'changes ona settings' do
          page.within('#js-gitpod-settings') do
            check 'Enable Ona integration'
            fill_in 'Ona URL', with: 'https://ona.test/'
          end

          expect_save_settings('#js-gitpod-settings')

          expect(current_settings.gitpod_url).to eq('https://ona.test/')
          expect(current_settings.gitpod_enabled).to be(true)
        end
      end

      context 'for GitLab for Jira App settings', feature_category: :integrations do
        it 'changes the settings' do
          page.within('#js-jira_connect-settings') do
            fill_in 'Jira Connect Application ID', with: '1234'
            fill_in 'Jira Connect Proxy URL', with: 'https://example.com'
            check 'Enable public key storage'
          end

          expect_save_settings('#js-jira_connect-settings')

          expect(current_settings.jira_connect_application_key).to eq('1234')
          expect(current_settings.jira_connect_proxy_url).to eq('https://example.com')
          expect(current_settings.jira_connect_public_key_storage_enabled).to be(true)
        end
      end

      context 'for GitLab for Slack app settings', feature_category: :integrations do
        let(:create_heading) { 'Create your GitLab for Slack app' }
        let(:configure_heading) { 'Configure the app settings' }
        let(:update_heading) { 'Update your Slack app' }

        it 'has all sections' do
          within_testid('slack-settings') do
            expect(page).to have_content(create_heading)
            expect(page).to have_content(configure_heading)
            expect(page).to have_content(update_heading)
          end
        end

        context 'when GitLab.com', :saas do
          it 'only has the configure section' do
            within_testid('slack-settings') do
              expect(page).to have_content(configure_heading)

              expect(page).not_to have_content(create_heading)
              expect(page).not_to have_content(update_heading)
            end
          end
        end

        it 'changes the settings' do
          within_testid('slack-settings') do
            check 'Enable GitLab for Slack app'
            fill_in 'Client ID', with: 'slack_app_id'
            fill_in 'Client secret', with: 'slack_app_secret'
            fill_in 'Signing secret', with: 'slack_app_signing_secret'
            fill_in 'Verification token', with: 'slack_app_verification_token'
          end

          expect_save_settings('slack-settings')

          expect(current_settings).to have_attributes(
            slack_app_enabled: true,
            slack_app_id: 'slack_app_id',
            slack_app_secret: 'slack_app_secret',
            slack_app_signing_secret: 'slack_app_signing_secret',
            slack_app_verification_token: 'slack_app_verification_token'
          )
        end
      end

      context 'for Web IDE Settings' do
        it 'changes and restores web ide extension host domain setting' do
          default_host_domain = ::WebIde::ExtensionMarketplace::DEFAULT_EXTENSION_HOST_DOMAIN

          page.within('#js-web-ide-settings') do
            expect(page).to have_field('Extension host domain', with: default_host_domain)

            fill_in 'Extension host domain', with: 'example.com'
          end

          expect_save_settings('#js-web-ide-settings')

          expect(current_settings.vscode_extension_marketplace_extension_host_domain)
            .to eq('example.com')

          page.within('#js-web-ide-settings') do
            click_link 'Restore default domain'
          end

          expect(page).to have_content 'The Web IDE extension host domain was restored to its default value.'
          expect(current_settings.vscode_extension_marketplace_extension_host_domain)
            .to eq(default_host_domain)
        end

        it 'changes single origin fallback setting' do
          expect(current_settings.vscode_extension_marketplace_single_origin_fallback_enabled).to be(true)
          page.within('#js-web-ide-settings') do
            expect(page).to have_checked_field('Enable single origin fallback')

            uncheck 'Enable single origin fallback'
          end

          expect_save_settings('#js-web-ide-settings')

          expect(current_settings.vscode_extension_marketplace_single_origin_fallback_enabled).to be(false)
        end
      end

      context 'for granular personal access token enforcement settings' do
        context 'when `granular_personal_access_tokens_enforcement` feature flag is disabled' do
          before do
            stub_feature_flags(granular_personal_access_tokens_enforcement: false)
            visit general_admin_application_settings_path
          end

          it 'does not show the enforcement section' do
            expect(page).not_to have_content(
              s_('AccessTokens|Fine-grained personal access tokens')
            )
          end
        end

        context 'when `granular_personal_access_tokens_enforcement` feature flag is enabled', :freeze_time do
          before do
            stub_feature_flags(granular_personal_access_tokens_enforcement: true)
            visit general_admin_application_settings_path
          end

          it 'shows the enforcement section' do
            expect(page).to have_content(
              s_('AccessTokens|Fine-grained personal access tokens')
            )
          end

          it 'shows the enforcement date input disabled by default', :js do
            within_testid('account-and-limit-settings-content') do
              expect(page).to have_field(
                s_('AccessTokens|Fine-grained personal access tokens enforcement date'),
                disabled: true
              )
            end
          end

          it 'enables the enforcement date input when the checkbox is checked', :js do
            within_testid('account-and-limit-settings-content') do
              check s_('AccessTokens|Require fine-grained personal access tokens after a specific date')

              expect(page).to have_field(
                s_('AccessTokens|Fine-grained personal access tokens enforcement date'),
                disabled: false
              )
            end
          end

          it 'saves the granular token enforcement settings' do
            within_testid('account-and-limit-settings-content') do
              check s_('AccessTokens|Require fine-grained personal access tokens after a specific date')
              fill_in s_('AccessTokens|Fine-grained personal access tokens enforcement date'), with: Date.current.to_s
            end

            expect_save_settings('account-and-limit-settings-content')

            expect(current_settings.enforce_granular_tokens).to be(true)
            expect(current_settings.granular_tokens_enforced_after).to eq(Date.current)
          end

          it 'shows an inline validation error when checkbox is checked but date is cleared' do
            within_testid('account-and-limit-settings-content') do
              check s_('AccessTokens|Require fine-grained personal access tokens after a specific date')
              fill_in s_('AccessTokens|Fine-grained personal access tokens enforcement date'), with: ''

              expect(page).to have_content(_('Please enter a date value.'))
            end
          end

          context 'when enforcement is already enabled' do
            before do
              current_settings.update_columns(
                personal_access_token_settings: {
                  enforce_granular_tokens: true,
                  granular_tokens_enforced_after: 1.month.ago.to_date
                }
              )

              visit general_admin_application_settings_path
            end

            it 'saving without changing the date does not throw an error' do
              expect_save_settings('account-and-limit-settings-content')
            end

            it 'unchecking the checkbox updates granular token enforcement settings', :js do
              within_testid('account-and-limit-settings-content') do
                uncheck s_('AccessTokens|Require fine-grained personal access tokens after a specific date')

                click_button 'Save changes'
              end

              expect(page).to have_content('Application settings saved successfully')
              expect(current_settings.enforce_granular_tokens).to be(false)
            end
          end
        end
      end
    end

    describe 'Analytics reports settings', feature_category: :value_stream_management do
      context 'when ClickHouse is configured' do
        before do
          allow(Gitlab::ClickHouse).to receive(:configured?).and_return(true)

          visit general_admin_application_settings_path
        end

        it 'enables clickhouse settings' do
          page.within('#js-analytics-settings') do
            check 'Enable ClickHouse'
          end

          expect_save_settings('#js-analytics-settings')
          expect(current_settings.use_clickhouse_for_analytics).to be_truthy
        end
      end

      context 'when ClickHouse is not configured' do
        before do
          allow(Gitlab::ClickHouse).to receive(:configured?).and_return(false)

          visit general_admin_application_settings_path
        end

        it 'disables checkbox to enable ClickHouse' do
          page.within('#js-analytics-settings') do |page|
            expect(page).to have_field('application_setting_use_clickhouse_for_analytics', disabled: true)
          end
        end
      end
    end

    context 'on Integrations page' do
      it 'enable hiding third party offers' do
        within_testid('third-party-offers-settings') do
          check 'Do not display content for customer experience improvement and offers from third parties'
        end

        expect_save_settings('third-party-offers-settings')

        expect(current_settings.hide_third_party_offers).to be true
      end

      it 'enabling Mailgun events', :aggregate_failures do
        within_testid('mailgun-settings') do
          check 'Enable Mailgun event receiver'
          fill_in 'Mailgun HTTP webhook signing key', with: 'MAILGUN_SIGNING_KEY'
        end

        expect_save_settings('mailgun-settings')

        expect(current_settings.mailgun_events_enabled).to be true
        expect(current_settings.mailgun_signing_key).to eq 'MAILGUN_SIGNING_KEY'
      end
    end
  end

  context 'when application setting :admin_mode is disabled' do
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

  def current_settings
    ApplicationSetting.current_without_cache
  end
end
