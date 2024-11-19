# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Using WebAuthn Devices for Authentication', :js, feature_category: :system_access do
  include Features::TwoFactorHelpers
  let(:app_id) { "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}" }

  before do
    WebAuthn.configuration.origin = app_id
  end

  it_behaves_like 'hardware device for 2fa', 'WebAuthn'

  describe 'registration' do
    let(:user) { create(:user) }

    before do
      gitlab_sign_in(user)
    end

    it 'shows an error when using a wrong password' do
      visit profile_account_path

      # First device
      enable_two_factor_authentication
      webauthn_device_registration(password: 'fake')
      expect(page).to have_content(_('You must provide a valid current password.'))
    end

    it 'allows registering more than one device' do
      visit profile_account_path

      # First device
      enable_two_factor_authentication
      first_device = webauthn_device_registration(password: user.password)
      expect(page).to have_content('Your WebAuthn device was registered!')
      copy_recovery_codes
      manage_two_factor_authentication

      # Second device
      second_device = webauthn_device_registration(name: 'My other device', password: user.password)
      expect(page).to have_content('Your WebAuthn device was registered!')

      expect(page).to have_content(first_device.name)
      expect(page).to have_content(second_device.name)
      expect(WebauthnRegistration.count).to eq(2)
    end

    it 'allows the same device to be registered for multiple users' do
      # First user
      visit profile_account_path
      enable_two_factor_authentication
      webauthn_device = webauthn_device_registration(password: user.password)
      expect(page).to have_content('Your WebAuthn device was registered!')
      gitlab_sign_out

      # Second user
      user = create(:user)
      gitlab_sign_in(user)
      visit profile_account_path
      enable_two_factor_authentication
      webauthn_device_registration(webauthn_device: webauthn_device, name: 'My other device', password: user.password)
      expect(page).to have_content('Your WebAuthn device was registered!')

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
          navigator.credentials.create = () => Promise.resolve(mockResponse);
        JS
      end

      it "doesn't register the device if there are errors" do
        visit profile_account_path
        enable_two_factor_authentication

        # Have the "webauthn device" respond with bad data
        page.execute_script(mock_register_js)
        click_on _('Set up new device')
        webauthn_fill_form_and_submit(password: user.password)
        expect(page).to have_content(_('Your WebAuthn device did not send a valid JSON response.'))

        expect(WebauthnRegistration.count).to eq(0)
      end

      it 'allows retrying registration' do
        visit profile_account_path
        enable_two_factor_authentication

        # Failed registration
        page.execute_script(mock_register_js)
        click_on _('Set up new device')
        webauthn_fill_form_and_submit(password: user.password)
        expect(page).to have_content(_('Your WebAuthn device did not send a valid JSON response.'))

        # Successful registration
        webauthn_device_registration(password: user.password)

        expect(page).to have_content('Your WebAuthn device was registered!')
        expect(WebauthnRegistration.count).to eq(1)
      end
    end
  end

  describe 'authentication' do
    let(:otp_required_for_login) { true }
    let(:user) { create(:user, webauthn_xid: WebAuthn.generate_user_id, otp_required_for_login: otp_required_for_login) }
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
          current_user = create(:user)
          gitlab_sign_in(current_user)
          visit profile_account_path
          enable_two_factor_authentication
          webauthn_device_registration(webauthn_device: webauthn_device, password: current_user.password)
          copy_recovery_codes
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

          device.respond_to_webauthn_authentication

          expect(page).to have_css('.sign-out-link', visible: false)

          gitlab_sign_out
        end
      end
    end
  end
end
