# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin mode login', :with_current_organization, feature_category: :system_access do
  include TermsHelper
  include UserLoginHelper
  include LdapHelpers

  describe 'with two-factor authentication', :js do
    def enter_code(code)
      fill_in 'user_otp_attempt', with: code
      click_button 'Verify code'
    end

    def expect_main_sign_in_success(otp)
      expect(page).to have_content(_('Enter verification code'))
      enter_code(otp)
      expect(page).to have_current_path root_path, ignore_query: true
    end

    def expect_admin_sign_in_success
      expect(page).to have_content(_('Admin mode is active.'))
      expect(page).to have_current_path admin_root_path, ignore_query: true
    end

    def expect_admin_sign_in_fail
      expect(page).to have_content(_('Invalid two-factor code.'))
    end

    context 'with valid username/password' do
      let(:user) { create(:admin, :two_factor) }

      context 'using one-time code' do
        before do
          submit_sign_in_form_for(user, remember: true) # This test checks that even when the user is remembered for sign-in, the user still needs to sign in for Admin mode.
          expect_main_sign_in_success(user.current_otp)
          enter_admin_mode(user, with_2fa: true)
        end

        it 'blocks login if we reuse the same code immediately', :freeze_time do
          repeated_otp = user.current_otp # the OTP is the same because of the :freeze_time
          enter_code(repeated_otp)
          expect_admin_sign_in_fail
        end

        context 'not re-using codes' do
          it 'allows login with valid code' do
            # TOTP has already been used for GitLab sign-in, wait 30 seconds for a new one
            travel_to(30.seconds.from_now) do
              enter_code(user.current_otp)
              expect_admin_sign_in_success
            end
          end

          it 'fails with invalid code' do
            enter_code('foo')
            expect_admin_sign_in_fail
          end

          it 'fails with invalid code, then succeeds with valid code' do
            enter_code('foo')
            expect_admin_sign_in_fail

            # TOTP has already been used for GitLab sign-in, wait 30 seconds for a new one
            travel_to(30.seconds.from_now) do
              enter_code(user.current_otp)
              expect_admin_sign_in_success
            end
          end

          context 'using backup code' do
            let(:codes) { user.generate_otp_backup_codes! }

            before do
              expect(codes.size).to eq 10

              # Ensure the generated codes get saved
              user.save!
            end

            context 'with valid code' do
              it 'allows login' do
                enter_code(codes.first)
                expect_admin_sign_in_success
              end

              it 'invalidates the used code' do
                enter_code(codes.first)
                expect_admin_sign_in_success
                expect(user.reload.otp_backup_codes.size).to eq(codes.size - 1)
              end
            end

            context 'with invalid code' do
              it 'blocks login' do
                code = codes.first
                expect(user.invalidate_otp_backup_code!(code)).to eq true

                user.save!
                expect(user.reload.otp_backup_codes.size).to eq 9

                enter_code(code)
                expect_admin_sign_in_fail
              end
            end
          end
        end
      end

      context 'when logging in via omniauth' do
        let(:user) { create(:omniauth_user, :admin, :two_factor, extern_uid: 'my-uid', provider: 'saml', password_automatically_set: false) }
        let(:mock_saml_response) do
          File.read('spec/fixtures/authentication/saml_response.xml')
        end

        before do
          stub_omniauth_saml_config(enabled: true, auto_link_saml_user: true, allow_single_sign_on: ['saml'], providers: [mock_saml_config_with_upstream_two_factor_authn_contexts])
        end

        context 'when authn_context is worth two factors' do
          let(:mock_saml_response) do
            File.read('spec/fixtures/authentication/saml_response.xml')
              .gsub(
                'urn:oasis:names:tc:SAML:2.0:ac:classes:Password',
                'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS'
              )
          end

          before do
            sign_in_using_saml!
            expect(page).to have_no_content(_('Enter verification code'))
            gitlab_enable_admin_mode_sign_in_via('saml', user, 'my-uid', saml_response: mock_saml_response)
          end

          it 'signs user in without prompting for second factor' do
            expect(page).to have_no_content(_('Enter verification code'))
            expect_admin_sign_in_success
          end
        end

        context 'when two factor authentication is required' do
          before do
            sign_in_using_saml!
            expect_main_sign_in_success(user.current_otp)
            expect_admin_sign_in_waiting_for_code_saml!(user)
          end

          it 'shows 2FA prompt after omniauth login' do
            # TOTP has already been used for GitLab sign-in, wait 30 seconds for a new one
            travel_to(30.seconds.from_now) do
              enter_code(user.current_otp)
              expect_admin_sign_in_success
            end
          end
        end

        def sign_in_using_saml!
          gitlab_sign_in_via('saml', user, 'my-uid', mock_saml_response)
        end

        def expect_admin_sign_in_waiting_for_code_saml!(user)
          gitlab_enable_admin_mode_sign_in_via('saml', user, 'my-uid', saml_response: mock_saml_response)
          expect(page).to have_content(_('Enter verification code'))
        end
      end

      context 'when logging in via ldap' do
        let(:uid) { 'my-uid' }
        let(:provider_label) { 'Main LDAP' }
        let(:provider_name) { 'main' }
        let(:provider) { "ldap#{provider_name}" }
        let(:ldap_server_config) do
          {
            'label' => provider_label,
            'provider_name' => provider,
            'attributes' => {},
            'encryption' => 'plain',
            'uid' => 'uid',
            'base' => 'dc=example,dc=com'
          }
        end

        let(:user) { create(:omniauth_user, :admin, :two_factor, extern_uid: uid, provider: provider) }

        before do
          setup_ldap(provider, user, uid, ldap_server_config)
        end

        context 'when two factor authentication is required' do
          before do
            sign_in_using_ldap!(user, provider_label)
            expect_main_sign_in_success(user.current_otp)
            expect_admin_sign_in_waiting_for_code_ldap!(user)
          end

          it 'shows 2FA prompt after ldap login' do
            # TOTP has already been used for GitLab sign-in, wait 30 seconds for a new one
            travel_to(30.seconds.from_now) do
              enter_code(user.current_otp)
              expect_admin_sign_in_success
            end
          end
        end

        def setup_ldap(provider, user, uid, ldap_server_config)
          stub_ldap_setting(enabled: true)

          allow(::Gitlab::Auth::Ldap::Config).to receive_messages(enabled: true, servers: [ldap_server_config])
          allow(Gitlab::Auth::OAuth::Provider).to receive_messages(providers: [provider.to_sym])

          Ldap::OmniauthCallbacksController.define_providers!
          Rails.application.reload_routes!

          mock_auth_hash(provider, uid, user.email)
          allow(Gitlab::Auth::Ldap::Access).to receive(:allowed?).with(user).and_return(true)

          allow_any_instance_of(ActionDispatch::Routing::RoutesProxy)
            .to receive(:"user_#{provider}_omniauth_callback_path")
            .and_return("/users/auth/#{provider}/callback")
        end

        def sign_in_using_ldap!(user, provider_label)
          visit new_user_session_path
          click_link provider_label
          fill_in 'username', with: user.username
          fill_in 'password', with: user.password
          click_button 'Sign in'
        end

        def expect_admin_sign_in_waiting_for_code_ldap!(user)
          visit new_admin_session_path
          click_link provider_label
          fill_in 'username', with: user.username
          fill_in 'password', with: user.password
          click_button 'Enter admin mode'
          expect(page).to have_content(_('Enter verification code'))
        end
      end
    end
  end
end
