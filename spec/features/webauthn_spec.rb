# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Using WebAuthn Devices for Authentication', :js do
  include Spec::Support::Helpers::Features::TwoFactorHelpers
  let(:app_id) { "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}" }

  before do
    WebAuthn.configuration.origin = app_id
  end

  it_behaves_like 'hardware device for 2fa', 'WebAuthn'

  describe 'registration' do
    let(:user) { create(:user) }

    before do
      gitlab_sign_in(user)
      user.update_attribute(:otp_required_for_login, true)
    end

    describe 'when 2FA via OTP is enabled' do
      it 'allows registering more than one device' do
        visit profile_account_path

        # First device
        manage_two_factor_authentication
        first_device = register_webauthn_device
        expect(page).to have_content('Your WebAuthn device was registered')

        # Second device
        second_device = register_webauthn_device(name: 'My other device')
        expect(page).to have_content('Your WebAuthn device was registered')

        expect(page).to have_content(first_device.name)
        expect(page).to have_content(second_device.name)
        expect(WebauthnRegistration.count).to eq(2)
      end
    end

    it 'allows the same device to be registered for multiple users' do
      # First user
      visit profile_account_path
      manage_two_factor_authentication
      webauthn_device = register_webauthn_device
      expect(page).to have_content('Your WebAuthn device was registered')
      gitlab_sign_out

      # Second user
      user = gitlab_sign_in(:user)
      user.update_attribute(:otp_required_for_login, true)
      visit profile_account_path
      manage_two_factor_authentication
      register_webauthn_device(webauthn_device, name: 'My other device')
      expect(page).to have_content('Your WebAuthn device was registered')

      expect(WebauthnRegistration.count).to eq(2)
    end

    context 'when there are form errors' do
      let(:mock_register_js) do
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
          navigator.credentials.create = function(_) {return Promise.resolve(mockResponse);}
        JS
      end

      it "doesn't register the device if there are errors" do
        visit profile_account_path
        manage_two_factor_authentication

        # Have the "webauthn device" respond with bad data
        page.execute_script(mock_register_js)
        click_on 'Set up new device'
        expect(page).to have_content('Your device was successfully set up')
        click_on 'Register device'

        expect(WebauthnRegistration.count).to eq(0)
        expect(page).to have_content('The form contains the following error')
        expect(page).to have_content('did not send a valid JSON response')
      end

      it 'allows retrying registration' do
        visit profile_account_path
        manage_two_factor_authentication

        # Failed registration
        page.execute_script(mock_register_js)
        click_on 'Set up new device'
        expect(page).to have_content('Your device was successfully set up')
        click_on 'Register device'
        expect(page).to have_content('The form contains the following error')

        # Successful registration
        register_webauthn_device

        expect(page).to have_content('Your WebAuthn device was registered')
        expect(WebauthnRegistration.count).to eq(1)
      end
    end
  end

  describe 'authentication' do
    let(:otp_required_for_login) { true }
    let(:user) { create(:user, webauthn_xid: WebAuthn.generate_user_id, otp_required_for_login: otp_required_for_login) }

    describe 'when there is only an U2F device' do
      let!(:u2f_device) do
        fake_device = U2F::FakeU2F.new(app_id) # "Client"
        u2f = U2F::U2F.new(app_id) # "Server"

        challenges = u2f.registration_requests.map(&:challenge)
        device_response = fake_device.register_response(challenges[0])
        device_registration_params = { device_response: device_response,
                                       name: 'My device' }

        U2fRegistration.register(user, app_id, device_registration_params, challenges)
        FakeU2fDevice.new(page, 'My device', fake_device)
      end

      it 'falls back to U2F' do
        # WebAuthn registration is automatically created with the U2fRegistration because of the after_create callback
        # so we need to delete it
        WebauthnRegistration.delete_all

        gitlab_sign_in(user)

        u2f_device.respond_to_u2f_authentication

        expect(page).to have_css('.sign-out-link', visible: false)
      end
    end

    describe 'when there is a WebAuthn device' do
      let!(:webauthn_device) do
        add_webauthn_device(app_id, user)
      end

      describe 'when 2FA via OTP is disabled' do
        let(:otp_required_for_login) { false }

        it 'allows logging in with the WebAuthn device' do
          gitlab_sign_in(user)

          webauthn_device.respond_to_webauthn_authentication

          expect(page).to have_css('.sign-out-link', visible: false)
        end
      end

      describe 'when 2FA via OTP is enabled' do
        it 'allows logging in with the WebAuthn device' do
          gitlab_sign_in(user)

          webauthn_device.respond_to_webauthn_authentication

          expect(page).to have_css('.sign-out-link', visible: false)
        end
      end

      describe 'when a given WebAuthn device has already been registered by another user' do
        describe 'but not the current user' do
          let(:other_user) { create(:user, webauthn_xid: WebAuthn.generate_user_id, otp_required_for_login: otp_required_for_login) }

          it 'does not allow logging in with that particular device' do
            # Register other user with a different WebAuthn device
            other_device = add_webauthn_device(app_id, other_user)

            # Try authenticating user with the old WebAuthn device
            gitlab_sign_in(user)
            other_device.respond_to_webauthn_authentication
            expect(page).to have_content('Authentication via WebAuthn device failed')
          end
        end

        describe "and also the current user" do
          # TODO Uncomment once WebAuthn::FakeClient supports passing credential options
          # (especially allow_credentials, as this is needed to specify which credential the
          # fake client should use. Currently, the first credential is always used).
          # There is an issue open for this: https://github.com/cedarcode/webauthn-ruby/issues/259
          it "allows logging in with that particular device" do
            pending("support for passing credential options in FakeClient")
            # Register current user with the same WebAuthn device
            current_user = gitlab_sign_in(:user)
            visit profile_account_path
            manage_two_factor_authentication
            register_webauthn_device(webauthn_device)
            gitlab_sign_out

            # Try authenticating user with the same WebAuthn device
            gitlab_sign_in(current_user)
            webauthn_device.respond_to_webauthn_authentication

            expect(page).to have_css('.sign-out-link', visible: false)
          end
        end
      end

      describe 'when a given WebAuthn device has not been registered' do
        it 'does not allow logging in with that particular device' do
          unregistered_device = FakeWebauthnDevice.new(page, 'My device')
          gitlab_sign_in(user)
          unregistered_device.respond_to_webauthn_authentication

          expect(page).to have_content('Authentication via WebAuthn device failed')
        end
      end

      describe 'when more than one device has been registered by the same user' do
        it 'allows logging in with either device' do
          first_device = add_webauthn_device(app_id, user)
          second_device = add_webauthn_device(app_id, user)

          # Authenticate as both devices
          [first_device, second_device].each do |device|
            gitlab_sign_in(user)
            # register_webauthn_device(device)
            device.respond_to_webauthn_authentication

            expect(page).to have_css('.sign-out-link', visible: false)

            gitlab_sign_out
          end
        end
      end
    end
  end
end
