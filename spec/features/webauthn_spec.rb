# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Using WebAuthn Authenticators', :js, feature_category: :system_access do
  include Features::TwoFactorHelpers
  let(:app_id) { "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}" }

  before do
    WebAuthn.configuration.origin = app_id
  end

  with_and_without_sign_in_form_vue do
    it_behaves_like 'OTP devices work independently of WebAuthn authenticators', 'WebAuthn'

    describe 'second factor' do
      describe 'registration' do
        let(:user) { create(:user) }

        before do
          gitlab_sign_in(user)
        end

        describe 'with valid registrations' do
          context 'with second_factor WebAuthn authenticators' do
            it 'allows a user to register more than one authenticator' do
              visit profile_two_factor_auth_path

              # First authenticator
              first_device = webauthn_device_registration(password: user.password)
              expect(page).to have_content('Your WebAuthn device was registered!')
              copy_recovery_codes

              # Second authenticator
              second_device = webauthn_device_registration(name: 'My other device', password: user.password)
              expect(page).to have_content('Your WebAuthn device was registered!')

              expect(page).to have_content(first_device.name)
              expect(page).to have_content(second_device.name)
            end
          end

          context 'with passkeys' do
            it 'allows a user to register multiple passkeys' do
              visit profile_two_factor_auth_path

              # First authenticator
              first_authenticator = passkey_registration(password: user.password)
              expect(page).to have_content(_('Passkey added successfully!'))

              # Second authenticator
              second_authenticator = passkey_registration(name: 'My other passkey', password: user.password)
              expect(page).to have_content(_('Passkey added successfully!'))

              expect(page).to have_content(first_authenticator.name)
              expect(page).to have_content(second_authenticator.name)
            end

            context 'with second-factor WebAuthn authenticators (WebAuthn & OTP) and passkeys 2FA parity' do
              it 'makes passkeys the default 2FA method when at least 1 2FA method is enabled' do
                visit profile_two_factor_auth_path

                # Add second_factor_authenticator (2FA enabled)
                webauthn_device_registration(password: user.password)
                expect(page).to have_content('Your WebAuthn device was registered!')
                copy_recovery_codes

                # Enables 2FA
                expect(page).to have_css('span.gl-badge-content', text: 'WebAuthn device') # Default 2FA: WebAuthn

                # Add passkey
                passkey_registration(name: 'My other passkey', password: user.password)
                expect(page).to have_content(_('Passkey added successfully!'))

                expect(page).to have_css('span.gl-badge-content', text: 'Passkey') # Default 2FA: Passkey

                # Delete last second_factor_authenticator but keep the passkey (passwordless-only usage)
                delete_webauthn_device(password: user.password)
                expect(page).to have_content('To use passkeys as your default two-factor authentication') # Disables 2FA

                # Add OTP (2FA enabled)
                user.otp_secret = User.generate_otp_secret(32)
                otp_authenticator_registration_and_copy_codes(user.reload.current_otp, user.password)
                expect(page).to have_text(_('2FA setup complete!'))

                expect(page).to have_css('span.gl-badge-content', text: 'Passkey') # Default 2FA: Passkey

                # Remove passkey
                delete_passkey_device(password: user.password)
                expect(page).to have_content('Passkey has been deleted!')

                # Retains 2FA
                expect(page).to have_css('span.gl-badge-content', text: 'One-time password authenticator') # Default 2FA: OTP
              end
            end
          end
        end

        describe 'with invalid registrations' do
          let(:bad_authenticator_response) do
            <<~JS
            const mockResponse = {
              type: 'public-key',
              id: '',
              rawId: '',
              response: {
                clientDataJSON: '',
                attestationObject: '',
              },
              getClientExtensionResults: () => {},
            };
            navigator.credentials.create = () => Promise.resolve(mockResponse);
            JS
          end

          context 'with an invalid authenticator response' do
            it "shows an error and does not register the device" do
              visit profile_two_factor_auth_path

              # Have the "webauthn device" respond with bad data
              page.execute_script(bad_authenticator_response)

              click_on _('Register device')
              click_on _('Set up new device')
              webauthn_fill_form_and_submit(password: user.password)

              expect(page).to have_content(_('Your WebAuthn device did not send a valid JSON response.'))
            end
          end

          context 'with invalid user UI inputs' do
            it 'shows an error when using a wrong password' do
              visit profile_two_factor_auth_path

              webauthn_device_registration(password: 'fake')

              expect(page).to have_content(_('You must provide a valid current password.'))
            end
          end

          context 'with retries' do
            it 'allows retrying registration' do
              visit profile_two_factor_auth_path

              # Failed registration
              page.execute_script(bad_authenticator_response)
              click_on _('Register device')
              click_on _('Set up new device')
              webauthn_fill_form_and_submit(password: user.password)
              expect(page).to have_content(_('Your WebAuthn device did not send a valid JSON response.'))

              # Successful registration
              webauthn_device_registration(password: user.password)

              expect(page).to have_content('Your WebAuthn device was registered!')
            end
          end

          context 'with passkeys' do
            context 'with an invalid authenticator response' do
              it "shows an error and does not register the passkey" do
                visit profile_two_factor_auth_path

                passkey_registration(password: user.password) do
                  page.execute_script(bad_authenticator_response)
                end

                expect(page).to have_current_path(profile_passkeys_path) # Stays on POST request path of passkeys#new
                expect(page).to have_content(_('Failed to connect to your device.'))
              end
            end

            context 'with invalid user UI inputs' do
              it 'shows an error when using a wrong password' do
                visit profile_two_factor_auth_path

                passkey_registration(password: 'fake')

                expect(page).to have_current_path(profile_passkeys_path) # Stays on POST request path of passkeys#new
                expect(page).to have_content(_('You must provide a valid current password.'))
              end
            end

            context 'with retries' do
              it 'allows retrying registration' do
                visit profile_two_factor_auth_path

                # Failed registration
                passkey_registration(password: 'fake')
                expect(page).to have_current_path(profile_passkeys_path) # Stays on POST request path of passkeys#new
                expect(page).to have_content(_('You must provide a valid current password.'))

                # Successful registration
                passkey ||= FakeWebauthnDevice.new(page, name: 'Retried passkey')
                passkey.respond_to_webauthn_registration
                click_button _('Try again')
                wait_for_requests
                passkey_fill_form_and_submit(name: 'Retried passkey', password: user.password)
                expect(page).to have_content(_('Passkey added successfully!'))
                expect(page).to have_current_path(profile_two_factor_auth_path)
              end
            end

            context 'when passkeys FF is disabled for 2FA registration' do
              before do
                stub_feature_flags(passkeys: false)
              end

              it 'does not render any passkeys content' do
                visit profile_two_factor_auth_path

                expect(page).not_to have_content("passkey")
              end
            end
          end
        end
      end

      describe 'authentication' do
        let(:user) do
          create(:user, :two_factor_via_otp, :two_factor_via_webauthn, :with_passkey, registrations_count: 1)
        end

        context 'with valid authentications' do
          context 'with second_factor authenticators' do
            it "allows a user to sign-in with an already registered WebAuthn authenticator" do
              webauthn_authenticator = add_webauthn_device(app_id, user)

              gitlab_sign_in(user)
              webauthn_authenticator.respond_to_webauthn_authentication

              expect(page).to have_current_path(root_path)
            end

            context 'when multiple authenticators have been registered by the same user' do
              it 'allows a user to sign-in with either authenticator' do
                first_device = add_webauthn_device(app_id, user)
                second_device = add_webauthn_device(app_id, user)

                # Authenticate as both devices
                [first_device, second_device].each do |device|
                  gitlab_sign_in(user)

                  device.respond_to_webauthn_authentication

                  expect(page).to have_current_path(root_path)

                  gitlab_sign_out
                end
              end
            end
          end

          context 'with passkeys' do
            it 'allows a user to sign-in with passkey, second_factor & OTP authenticators' do
              # with passkey
              passkey = add_passkey(app_id, user)
              gitlab_sign_in(user)
              passkey.respond_to_webauthn_authentication
              expect(page).to have_current_path(root_path)
              gitlab_sign_out

              # with WebAuthn
              second_factor_authenticator = add_webauthn_device(app_id, user)
              gitlab_sign_in(user)
              second_factor_authenticator.respond_to_webauthn_authentication
              expect(page).to have_current_path(root_path)
              gitlab_sign_out

              # with OTP
              gitlab_sign_in(user)
              add_otp(user)
              expect(page).to have_current_path(root_path)
              gitlab_sign_out
            end
          end
        end

        context 'with invalid authentications' do
          let(:other_user) { create(:user, :two_factor_via_webauthn, registrations_count: 1) }

          context 'when a given WebAuthn authenticator in GitLab is not owned by a user' do
            it 'does not allow a user to sign-in in with that particular authenticator' do
              webauthn_authenticator = add_webauthn_device(app_id, user)

              # Sign-in with a 2FA enabled user & perform the user verification
              gitlab_sign_in(other_user)
              webauthn_authenticator.respond_to_webauthn_authentication

              expect(page).to have_content('Authentication via WebAuthn device failed')
            end
          end

          context 'with retries' do
            it 'allows retrying authentication' do
              webauthn_authenticator = add_webauthn_device(app_id, user)

              # Failed authentication
              gitlab_sign_in(other_user)
              webauthn_authenticator.respond_to_webauthn_authentication

              expect(page).to have_content('Authentication via WebAuthn device failed')

              # Successful authentication
              webauthn_authenticator2 = add_webauthn_device(app_id, other_user)
              webauthn_authenticator2.respond_to_webauthn_authentication

              expect(page).to have_current_path(root_path)
            end
          end

          context 'with passkeys' do
            context 'when a given passkey in GitLab is not owned by a user' do
              it 'does not allow a user to sign-in in with that particular authenticator' do
                passkey = add_passkey(app_id, user)

                gitlab_sign_in(other_user)
                passkey.respond_to_webauthn_authentication

                expect(page).to have_content('Failed to connect to your device')
              end
            end

            context 'with retries' do
              it 'allows retrying authentication' do
                passkey = add_passkey(app_id, user)

                # Failed authentication
                gitlab_sign_in(other_user)
                passkey.respond_to_webauthn_authentication
                expect(page).to have_content('Failed to connect to your device')

                # Successful authentication
                passkey_for_other_user = add_passkey(app_id, other_user)
                passkey_for_other_user.respond_to_webauthn_authentication

                expect(page).to have_current_path(root_path)
              end
            end

            context 'when passkeys FF is disabled for 2FA authentication' do
              before do
                stub_feature_flags(passkeys: false)
              end

              it 'allows a user to sign-in with second_factor & OTP authenticators, not passkeys' do
                # with passkey
                passkey = add_passkey(app_id, user)
                gitlab_sign_in(user)
                passkey.respond_to_webauthn_authentication
                expect(page).to have_current_path(new_user_session_path)

                click_button('Try again?')

                # with WebAuthn
                second_factor_authenticator = add_webauthn_device(app_id, user)
                gitlab_sign_in(user)
                second_factor_authenticator.respond_to_webauthn_authentication
                expect(page).to have_current_path(root_path)
                gitlab_sign_out

                # with OTP
                gitlab_sign_in(user)
                add_otp(user)
                expect(page).to have_current_path(root_path)
                gitlab_sign_out
              end
            end
          end
        end
      end
    end

    describe 'passwordless' do
      describe 'authentication' do
        context 'with passkeys' do
          let(:user) { create(:user) }

          context 'with valid authentications' do
            it 'allows a user to sign-in without a password' do
              passkey = add_passkey(app_id, user)

              visit root_path

              click_button(_('Passkey'))
              expect(page).to have_current_path(users_passkeys_sign_in_path)

              passkey.respond_to_webauthn_authentication(passkey: true)
              click_button _('Try again')

              expect(page).to have_current_path(root_path)
            end
          end

          context 'with invalid authentications' do
            context 'when a given passkey in GitLab is not owned by a user' do
              it 'does not allow a user to sign-in in with that particular authenticator' do
                passkey = add_passkey(app_id, user, save_passkey: false)

                visit root_path
                click_button(_('Passkey'))
                expect(page).to have_current_path(users_passkeys_sign_in_path)

                passkey.respond_to_webauthn_authentication(passkey: true)
                click_button _('Try again')

                expect(page).to have_content('Failed to connect to your device')
              end
            end

            context 'with retries' do
              it 'allows retrying authentication' do
                # Failed authentication
                passkey = add_passkey(app_id, user, save_passkey: false)
                visit root_path
                click_button(_('Passkey'))
                expect(page).to have_current_path(users_passkeys_sign_in_path)
                passkey.respond_to_webauthn_authentication(passkey: true)
                click_button _('Try again')
                expect(page).to have_content('Failed to connect to your device')

                # Successful authentication
                passkey = add_passkey(app_id, user)
                passkey.respond_to_webauthn_authentication(passkey: true)
                click_button _('Try again')

                expect(page).to have_current_path(root_path)
              end
            end
          end

          context 'when passkeys FF is disabled' do
            before do
              stub_feature_flags(passkeys: false)
            end

            it 'does not show the Passkey button' do
              visit root_path

              expect(page).not_to have_button(_('Passkey'))
            end
          end
        end
      end
    end
  end
end
