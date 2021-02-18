# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Using U2F (Universal 2nd Factor) Devices for Authentication', :js do
  include Spec::Support::Helpers::Features::TwoFactorHelpers

  before do
    stub_feature_flags(webauthn: false)
  end

  it_behaves_like 'hardware device for 2fa', 'U2F'

  describe "registration" do
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
        first_device = register_u2f_device
        expect(page).to have_content('Your U2F device was registered')

        # Second device
        second_device = register_u2f_device(name: 'My other device')
        expect(page).to have_content('Your U2F device was registered')

        expect(page).to have_content(first_device.name)
        expect(page).to have_content(second_device.name)
        expect(U2fRegistration.count).to eq(2)
      end
    end

    it 'allows the same device to be registered for multiple users' do
      # U2f specs will be removed after WebAuthn migration completed
      pending('FakeU2fDevice has static key handle, '\
              'leading to duplicate credential_xid for WebAuthn during migration, '\
              'resulting in unique constraint violation')

      # First user
      visit profile_account_path
      manage_two_factor_authentication
      u2f_device = register_u2f_device
      expect(page).to have_content('Your U2F device was registered')
      gitlab_sign_out

      # Second user
      user = gitlab_sign_in(:user)
      user.update_attribute(:otp_required_for_login, true)
      visit profile_account_path
      manage_two_factor_authentication
      register_u2f_device(u2f_device, name: 'My other device')
      expect(page).to have_content('Your U2F device was registered')

      expect(U2fRegistration.count).to eq(2)
    end

    context "when there are form errors" do
      it "doesn't register the device if there are errors" do
        visit profile_account_path
        manage_two_factor_authentication

        # Have the "u2f device" respond with bad data
        page.execute_script("u2f.register = function(_,_,_,callback) { callback('bad response'); };")
        click_on 'Set up new device'
        expect(page).to have_content('Your device was successfully set up')
        click_on 'Register device'

        expect(U2fRegistration.count).to eq(0)
        expect(page).to have_content("The form contains the following error")
        expect(page).to have_content("did not send a valid JSON response")
      end

      it "allows retrying registration" do
        visit profile_account_path
        manage_two_factor_authentication

        # Failed registration
        page.execute_script("u2f.register = function(_,_,_,callback) { callback('bad response'); };")
        click_on 'Set up new device'
        expect(page).to have_content('Your device was successfully set up')
        click_on 'Register device'
        expect(page).to have_content("The form contains the following error")

        # Successful registration
        register_u2f_device

        expect(page).to have_content('Your U2F device was registered')
        expect(U2fRegistration.count).to eq(1)
      end
    end
  end

  describe "authentication" do
    let(:user) { create(:user) }

    before do
      # Register and logout
      gitlab_sign_in(user)
      user.update_attribute(:otp_required_for_login, true)
      visit profile_account_path
      manage_two_factor_authentication
      @u2f_device = register_u2f_device
      gitlab_sign_out
    end

    describe "when 2FA via OTP is disabled" do
      it "allows logging in with the U2F device" do
        user.update_attribute(:otp_required_for_login, false)
        gitlab_sign_in(user)

        @u2f_device.respond_to_u2f_authentication

        expect(page).to have_css('.sign-out-link', visible: false)
      end
    end

    describe "when 2FA via OTP is enabled" do
      it "allows logging in with the U2F device" do
        user.update_attribute(:otp_required_for_login, true)
        gitlab_sign_in(user)

        @u2f_device.respond_to_u2f_authentication

        expect(page).to have_css('.sign-out-link', visible: false)
      end
    end

    describe "when a given U2F device has already been registered by another user" do
      describe "but not the current user" do
        it "does not allow logging in with that particular device" do
          # Register current user with the different U2F device
          current_user = gitlab_sign_in(:user)
          current_user.update_attribute(:otp_required_for_login, true)
          visit profile_account_path
          manage_two_factor_authentication
          register_u2f_device(name: 'My other device')
          gitlab_sign_out

          # Try authenticating user with the old U2F device
          gitlab_sign_in(current_user)
          @u2f_device.respond_to_u2f_authentication
          expect(page).to have_content('Authentication via U2F device failed')
        end
      end

      describe "and also the current user" do
        it "allows logging in with that particular device" do
          # U2f specs will be removed after WebAuthn migration completed
          pending('FakeU2fDevice has static key handle, '\
                  'leading to duplicate credential_xid for WebAuthn during migration, '\
                  'resulting in unique constraint violation')

          # Register current user with the same U2F device
          current_user = gitlab_sign_in(:user)
          current_user.update_attribute(:otp_required_for_login, true)
          visit profile_account_path
          manage_two_factor_authentication
          register_u2f_device(@u2f_device)
          gitlab_sign_out

          # Try authenticating user with the same U2F device
          gitlab_sign_in(current_user)
          @u2f_device.respond_to_u2f_authentication

          expect(page).to have_css('.sign-out-link', visible: false)
        end
      end
    end

    describe "when a given U2F device has not been registered" do
      it "does not allow logging in with that particular device" do
        unregistered_device = FakeU2fDevice.new(page, 'My device')
        gitlab_sign_in(user)
        unregistered_device.respond_to_u2f_authentication

        expect(page).to have_content('Authentication via U2F device failed')
      end
    end

    describe "when more than one device has been registered by the same user" do
      it "allows logging in with either device" do
        # Register first device
        user = gitlab_sign_in(:user)
        user.update_attribute(:otp_required_for_login, true)
        visit profile_two_factor_auth_path
        expect(page).to have_content("Your device needs to be set up.")
        first_device = register_u2f_device

        # Register second device
        visit profile_two_factor_auth_path
        expect(page).to have_content("Your device needs to be set up.")
        second_device = register_u2f_device(name: 'My other device')
        gitlab_sign_out

        # Authenticate as both devices
        [first_device, second_device].each do |device|
          gitlab_sign_in(user)
          device.respond_to_u2f_authentication

          expect(page).to have_css('.sign-out-link', visible: false)

          gitlab_sign_out
        end
      end
    end
  end
end
