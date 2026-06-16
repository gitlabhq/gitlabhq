# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin updates general settings', feature_category: :settings do
  include StubENV
  include TermsHelper
  include Features::SettingsHelpers

  let_it_be(:admin, freeze: false) { create(:admin) }

  context 'when application setting :admin_mode is enabled', :request_store, :enable_admin_mode do
    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      sign_in(admin)
    end

    context 'on General page' do
      before do
        visit general_admin_application_settings_path
      end

      it 'change visibility settings' do
        within_testid('admin-visibility-access-settings') do
          choose_option("application_setting_default_project_visibility_20")

          expect_save_settings

          expect_field_checked("application_setting_default_project_visibility_20")
        end
      end

      it 'uncheck all restricted visibility levels', :aggregate_failures do
        within_testid('admin-visibility-access-settings') do
          within_testid('restricted-visibility-levels') do
            click_unchecked_field s_('VisibilityLevel|Public')
            click_unchecked_field s_('VisibilityLevel|Internal')
          end

          expect_save_settings(refresh: true)

          within_testid('restricted-visibility-levels') do
            expect_field_checked s_('VisibilityLevel|Public')
            expect_field_checked s_('VisibilityLevel|Internal')

            click_checked_field s_('VisibilityLevel|Public')
            click_checked_field s_('VisibilityLevel|Internal')
          end

          expect_save_settings

          within_testid('restricted-visibility-levels') do
            expect_field_unchecked s_('VisibilityLevel|Public')
            expect_field_unchecked s_('VisibilityLevel|Internal')
          end
        end
      end

      it 'change deletion settings', :js do
        within_testid('admin-visibility-access-settings') do
          fill_field_with_new_value(s_('DeletionSettings|Retention period'), '40')

          expect_save_settings

          expect_field_value(s_('DeletionSettings|Retention period'), '40')
        end
      end

      it 'modify import sources' do
        within_testid('admin-import-export-settings') do
          click_unchecked_field("Repository by URL")

          expect_save_settings

          expect_field_checked("Repository by URL")
        end
      end

      it 'change Visibility and Access Controls', :aggregate_failures do
        within_testid('admin-import-export-settings') do
          within_testid('project-export') do
            click_checked_field s_('AdminSettings|Enabled')
          end

          within_testid('bulk-import') do
            click_unchecked_field s_('AdminSettings|Enabled')
          end

          within_testid('silent-admin-exports') do
            click_unchecked_field s_('AdminSettings|Enabled')
          end

          expect_save_settings

          within_testid('project-export') do
            expect_field_unchecked s_('AdminSettings|Enabled')
          end

          within_testid('bulk-import') do
            expect_field_checked s_('AdminSettings|Enabled')
          end

          within_testid('silent-admin-exports') do
            expect_field_checked s_('AdminSettings|Enabled')
          end
        end
      end

      it 'change Keys settings', :aggregate_failures do
        forbidden = ApplicationSetting::FORBIDDEN_KEY_VALUE.to_s

        within_testid('admin-visibility-access-settings') do
          select 'Are forbidden', from: 'RSA SSH keys'
          select 'Are allowed', from: 'DSA SSH keys'
          select 'Must be at least 384 bits', from: 'ECDSA SSH keys'
          select 'Are forbidden', from: 'ED25519 SSH keys'
          select 'Are forbidden', from: 'ECDSA_SK SSH keys'
          select 'Are forbidden', from: 'ED25519_SK SSH keys'

          expect_save_settings

          expect_field_value('RSA SSH keys', forbidden)
          expect_field_value('DSA SSH keys', '0')
          expect_field_value('ECDSA SSH keys', '384')
          expect_field_value('ED25519 SSH keys', forbidden)
          expect_field_value('ECDSA_SK SSH keys', forbidden)
          expect_field_value('ED25519_SK SSH keys', forbidden)
        end
      end

      it 'change Account and Limit Settings' do
        within_testid('account-and-limit-settings-content') do
          click_checked_field(_('Gravatar enabled'))

          expect_save_settings

          expect_field_unchecked(_('Gravatar enabled'))
        end
      end

      it 'change Maximum export size' do
        within_testid('admin-import-export-settings') do
          fill_field_with_new_value(_('Maximum export size (MiB)'), '25')

          expect_save_settings

          expect_field_value(_('Maximum export size (MiB)'), '25')
        end
      end

      it 'change Maximum import size' do
        within_testid('admin-import-export-settings') do
          fill_field_with_new_value(_('Maximum import size (MiB)'), '15')

          expect_save_settings

          expect_field_value(_('Maximum import size (MiB)'), '15')
        end
      end

      it 'change Diff limits settings', :aggregate_failures do
        within_testid('diff-limits-settings') do
          fill_field_with_new_value(_('Maximum diff versions per merge request'), '500')
          fill_field_with_new_value(_('Maximum diff commits per merge request'), '500000')

          expect_save_settings

          expect_field_value(_('Maximum diff versions per merge request'), '500')
          expect_field_value(_('Maximum diff commits per merge request'), '500000')
        end
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
            within_testid('account-and-limit-settings-content') do
              click_unchecked_field(_('Deactivate dormant users after a period of inactivity'))

              expect_save_settings

              expect_field_checked(_('Deactivate dormant users after a period of inactivity'))
            end
          end

          it 'change dormant users period', :js, :aggregate_failures do
            expect(page).to have_field(_('Days of inactivity before deactivation'), disabled: true)

            within_testid('account-and-limit-settings-content') do
              click_unchecked_field(_('Deactivate dormant users after a period of inactivity'))
              fill_field_with_new_value(_('Days of inactivity before deactivation'), '180')

              expect_save_settings

              expect_field_checked(_('Deactivate dormant users after a period of inactivity'))
              expect_field_value(_('Days of inactivity before deactivation'), '180')
            end

            expect(page).to have_field(_('Days of inactivity before deactivation'), disabled: false)
          end

          it 'displays dormant users period field validation error', :js,
            quarantine: { issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/20325',
                          type: 'flaky' } do
            selector = '#application_setting_deactivate_dormant_users_period_error'
            expect(page).not_to have_selector(selector, visible: :visible)

            within_testid('account-and-limit-settings-content') do
              check 'application_setting_deactivate_dormant_users'
              fill_in _('application_setting_deactivate_dormant_users_period'), with: '30'
              click_button _('Save changes')
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
              click_checked_field(s_('ApplicationSettings|Require admin approval for new user accounts'))

              expect_save_settings

              expect_field_unchecked(s_('ApplicationSettings|Require admin approval for new user accounts'))
            end
          end
        end

        context 'for email confirmation settings' do
          it "is set to 'hard' by default" do
            expect(current_settings.email_confirmation_setting).to eq('off')
          end

          it 'changes the setting', :js do
            within_testid('sign-up-restrictions-settings-content') do
              choose_option('Hard')

              expect_save_settings

              expect_field_checked('Hard')
            end
          end
        end
      end

      it 'change Sign-in restrictions' do
        within_testid('signin-settings') do
          fill_field_with_new_value(_('Home page URL'), 'https://about.gitlab.com/')

          expect_save_settings

          expect_field_value(_('Home page URL'), 'https://about.gitlab.com/')
        end
      end

      it 'terms of Service', :js do
        # Already have the admin accept terms, so they don't need to accept in this spec.
        _existing_terms = create(:term)
        accept_terms(admin)

        within_testid('terms-settings') do
          check _('All users must accept the Terms of Service and Privacy Policy to access GitLab')
          fill_in 'Terms of Service Agreement', with: 'Be nice!'
          click_button _('Save changes')
        end

        within_testid('terms-content') do
          expect(page).to have_content('Be nice!')
        end

        click_button 'Accept terms'

        expect(page).to have_current_path(general_admin_application_settings_path, ignore_query: true)
      end

      context 'for project and group access tokens settings' do
        it 'changes inactive_resource_access_tokens_delete_after_days' do
          within_testid('account-and-limit-settings-content') do
            fill_field_with_new_value(
              s_('ResourceAccessTokensInstanceSettings|Inactive project and group access token retention period'), '42')

            expect_save_settings

            expect_field_value(
              s_('ResourceAccessTokensInstanceSettings|Inactive project and group access token retention period'), '42')
          end
        end
      end

      it 'modify oauth providers' do
        within_testid('signin-settings') do
          click_checked_field('Google')

          expect_save_settings

          expect_field_unchecked('Google')
        end
      end

      it 'oauth providers do not raise validation errors when saving unrelated changes' do
        within_testid('signin-settings') do
          click_checked_field('Google')

          expect_save_settings(refresh: true)
        end

        expect(current_settings.disabled_oauth_sign_in_sources).to include('google_oauth2')

        # Remove google_oauth2 from the Omniauth strategies
        allow(Devise).to receive(:omniauth_providers).and_return([])

        # Save an unrelated setting
        within_testid('terms-settings') { expect_save_settings }

        expect(current_settings.disabled_oauth_sign_in_sources).to include('google_oauth2')
      end

      it 'configure web terminal' do
        within_testid('terminal-settings') do
          fill_field_with_new_value(_('Max session time'), '15')

          expect_save_settings

          expect_field_value(_('Max session time'), '15')
        end
      end

      context 'when configuring Ona' do
        it 'changes ona settings', :aggregate_failures do
          within('#js-gitpod-settings') do
            click_unchecked_field(s_('Gitpod|Enable Ona integration'))
            fill_field_with_new_value(s_('Gitpod|Ona URL'), 'https://ona.test/')

            expect_save_settings

            expect_field_checked(s_('Gitpod|Enable Ona integration'))
            expect_field_value(s_('Gitpod|Ona URL'), 'https://ona.test/')
          end
        end
      end

      context 'for GitLab for Jira App settings', feature_category: :integrations do
        it 'changes the settings', :aggregate_failures do
          within('#js-jira_connect-settings') do
            fill_field_with_new_value(s_('JiraConnect|Jira Connect Application ID'), '1234')
            fill_field_with_new_value(s_('JiraConnect|Jira Connect Proxy URL'), 'https://example.com')
            click_unchecked_field(s_('JiraConnect|Enable public key storage'))

            expect_save_settings

            expect_field_value(s_('JiraConnect|Jira Connect Application ID'), '1234')
            expect_field_value(s_('JiraConnect|Jira Connect Proxy URL'), 'https://example.com')
            expect_field_checked(s_('JiraConnect|Enable public key storage'))
          end
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

        it 'changes the settings', :aggregate_failures do
          within_testid('slack-settings') do
            click_unchecked_field(s_('ApplicationSettings|Enable GitLab for Slack app'))
            fill_field_with_new_value(s_('SlackIntegration|Client ID'), 'slack_app_id')
            fill_field_with_new_value(s_('SlackIntegration|Client secret'), 'slack_app_secret')
            fill_field_with_new_value(s_('SlackIntegration|Signing secret'), 'slack_app_signing_secret')
            fill_field_with_new_value(s_('SlackIntegration|Verification token'), 'slack_app_verification_token')

            expect_save_settings

            expect_field_checked(s_('ApplicationSettings|Enable GitLab for Slack app'))
            expect_field_value(s_('SlackIntegration|Client ID'), 'slack_app_id')
            expect_field_value(s_('SlackIntegration|Client secret'), 'slack_app_secret')
            expect_field_value(s_('SlackIntegration|Signing secret'), 'slack_app_signing_secret')
            expect_field_value(s_('SlackIntegration|Verification token'), 'slack_app_verification_token')
          end
        end
      end

      context 'for Web IDE Settings' do
        it 'changes and restores web ide extension host domain setting' do
          default_host_domain = ::WebIde::ExtensionMarketplace::DEFAULT_EXTENSION_HOST_DOMAIN

          within('#js-web-ide-settings') do
            fill_field_with_new_value('Extension host domain', 'example.com')

            expect_save_settings

            expect_field_value('Extension host domain', 'example.com')

            click_link 'Restore default domain'
          end

          expect(page).to have_content 'The Web IDE extension host domain was restored to its default value.'
          page.within('#js-web-ide-settings') do
            expect_field_value('Extension host domain', default_host_domain)
          end
        end

        it 'changes single origin fallback setting' do
          within('#js-web-ide-settings') do
            click_checked_field(s_('AdminSettings|Enable single origin fallback'))

            expect_save_settings

            expect_field_unchecked(s_('AdminSettings|Enable single origin fallback'))
          end
        end
      end
    end

    describe 'Personal Access Token enforcement settings' do
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
        end

        context 'when enforcement is not yet enabled' do
          before do
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
              click_unchecked_field(
                s_('AccessTokens|Require fine-grained personal access tokens after a specific date')
              )

              expect(page).to have_field(
                s_('AccessTokens|Fine-grained personal access tokens enforcement date'),
                disabled: false
              )
            end
          end

          it 'saves the granular token enforcement settings', :aggregate_failures do
            within_testid('account-and-limit-settings-content') do
              click_unchecked_field(
                s_('AccessTokens|Require fine-grained personal access tokens after a specific date')
              )
              fill_field_with_new_value(s_('AccessTokens|Fine-grained personal access tokens enforcement date'),
                1.month.from_now.to_date.to_s)

              expect_save_settings

              expect_field_checked(
                s_('AccessTokens|Require fine-grained personal access tokens after a specific date')
              )
              expect_field_value(s_('AccessTokens|Fine-grained personal access tokens enforcement date'),
                1.month.from_now.to_date.to_s)
            end
          end

          it 'shows an inline validation error when checkbox is checked but date is cleared' do
            within_testid('account-and-limit-settings-content') do
              click_unchecked_field(
                s_('AccessTokens|Require fine-grained personal access tokens after a specific date')
              )
              fill_in s_('AccessTokens|Fine-grained personal access tokens enforcement date'), with: ''

              expect(page).to have_content(_('Please enter a date value.'))
            end
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
            within_testid('account-and-limit-settings-content') { expect_save_settings }
          end

          it 'unchecking the checkbox updates granular token enforcement settings', :js do
            within_testid('account-and-limit-settings-content') do
              click_checked_field(
                s_('AccessTokens|Require fine-grained personal access tokens after a specific date')
              )

              expect_save_settings

              expect_field_unchecked(
                s_('AccessTokens|Require fine-grained personal access tokens after a specific date')
              )
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
          within('#js-analytics-settings') do
            click_unchecked_field(_('Enable ClickHouse'))

            expect_save_settings

            expect_field_checked(_('Enable ClickHouse'))
          end
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
      before do
        visit general_admin_application_settings_path
      end

      it 'enable hiding third party offers' do
        within_testid('third-party-offers-settings') do
          click_unchecked_field(
            _('Do not display content for customer experience improvement and offers from third parties')
          )

          expect_save_settings

          expect_field_checked(
            _('Do not display content for customer experience improvement and offers from third parties')
          )
        end
      end

      it 'enabling Mailgun events', :aggregate_failures do
        within_testid('mailgun-settings') do
          click_unchecked_field(_('Enable Mailgun event receiver'))
          fill_field_with_new_value(_('Mailgun HTTP webhook signing key'), 'MAILGUN_SIGNING_KEY')

          expect_save_settings

          expect_field_checked(_('Enable Mailgun event receiver'))
          expect_field_value(_('Mailgun HTTP webhook signing key'), 'MAILGUN_SIGNING_KEY')
        end
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
    ApplicationSetting.current_without_cache || Gitlab::CurrentSettings.current_application_settings
  end
end
