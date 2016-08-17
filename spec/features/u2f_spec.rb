require 'spec_helper'

feature 'Using U2F (Universal 2nd Factor) Devices for Authentication', feature: true, js: true do
  include WaitForAjax

  before { allow_any_instance_of(U2fHelper).to receive(:inject_u2f_api?).and_return(true) }

  def manage_two_factor_authentication
    click_on 'Manage Two-Factor Authentication'
    expect(page).to have_content("Setup New U2F Device")
    wait_for_ajax
  end

  def register_u2f_device(u2f_device = nil)
    u2f_device ||= FakeU2fDevice.new(page)
    u2f_device.respond_to_u2f_registration
    click_on 'Setup New U2F Device'
    expect(page).to have_content('Your device was successfully set up')
    click_on 'Register U2F Device'
    u2f_device
  end

  describe "registration" do
    let(:user) { create(:user) }

    before do
      login_as(user)
      user.update_attribute(:otp_required_for_login, true)
    end

    describe 'when 2FA via OTP is disabled' do
      before { user.update_attribute(:otp_required_for_login, false) }

      it 'does not allow registering a new device' do
        visit profile_account_path
        click_on 'Enable Two-Factor Authentication'

        expect(page).to have_button('Setup New U2F Device', disabled: true)
      end
    end

    describe 'when 2FA via OTP is enabled' do
      it 'allows registering a new device' do
        visit profile_account_path
        manage_two_factor_authentication
        expect(page.body).to match("You've already enabled two-factor authentication using mobile")

        register_u2f_device

        expect(page.body).to match('Your U2F device was registered')
      end

      it 'allows registering more than one device' do
        visit profile_account_path

        # First device
        manage_two_factor_authentication
        register_u2f_device
        expect(page.body).to match('Your U2F device was registered')

        # Second device
        manage_two_factor_authentication
        register_u2f_device
        expect(page.body).to match('Your U2F device was registered')
        manage_two_factor_authentication
        expect(page.body).to match('You have 2 U2F devices registered')
      end
    end

    it 'allows the same device to be registered for multiple users' do
      # First user
      visit profile_account_path
      manage_two_factor_authentication
      u2f_device = register_u2f_device
      expect(page.body).to match('Your U2F device was registered')
      logout

      # Second user
      user = login_as(:user)
      user.update_attribute(:otp_required_for_login, true)
      visit profile_account_path
      manage_two_factor_authentication
      register_u2f_device(u2f_device)
      expect(page.body).to match('Your U2F device was registered')

      expect(U2fRegistration.count).to eq(2)
    end

    context "when there are form errors" do
      it "doesn't register the device if there are errors" do
        visit profile_account_path
        manage_two_factor_authentication

        # Have the "u2f device" respond with bad data
        page.execute_script("u2f.register = function(_,_,_,callback) { callback('bad response'); };")
        click_on 'Setup New U2F Device'
        expect(page).to have_content('Your device was successfully set up')
        click_on 'Register U2F Device'

        expect(U2fRegistration.count).to eq(0)
        expect(page.body).to match("The form contains the following error")
        expect(page.body).to match("did not send a valid JSON response")
      end

      it "allows retrying registration" do
        visit profile_account_path
        manage_two_factor_authentication

        # Failed registration
        page.execute_script("u2f.register = function(_,_,_,callback) { callback('bad response'); };")
        click_on 'Setup New U2F Device'
        expect(page).to have_content('Your device was successfully set up')
        click_on 'Register U2F Device'
        expect(page.body).to match("The form contains the following error")

        # Successful registration
        register_u2f_device

        expect(page.body).to match('Your U2F device was registered')
        expect(U2fRegistration.count).to eq(1)
      end
    end
  end

  describe "authentication" do
    let(:user) { create(:user) }

    before do
      # Register and logout
      login_as(user)
      user.update_attribute(:otp_required_for_login, true)
      visit profile_account_path
      manage_two_factor_authentication
      @u2f_device = register_u2f_device
      logout
    end

    describe "when 2FA via OTP is disabled" do
      it "allows logging in with the U2F device" do
        login_with(user)

        @u2f_device.respond_to_u2f_authentication
        click_on "Login Via U2F Device"
        expect(page.body).to match('We heard back from your U2F device')
        click_on "Authenticate via U2F Device"

        expect(page.body).to match('Signed in successfully')
      end
    end

    describe "when 2FA via OTP is enabled" do
      it "allows logging in with the U2F device" do
        user.update_attribute(:otp_required_for_login, true)
        login_with(user)

        @u2f_device.respond_to_u2f_authentication
        click_on "Login Via U2F Device"
        expect(page.body).to match('We heard back from your U2F device')
        click_on "Authenticate via U2F Device"

        expect(page.body).to match('Signed in successfully')
      end
    end

    describe "when a given U2F device has already been registered by another user" do
      describe "but not the current user" do
        it "does not allow logging in with that particular device" do
          # Register current user with the different U2F device
          current_user = login_as(:user)
          current_user.update_attribute(:otp_required_for_login, true)
          visit profile_account_path
          manage_two_factor_authentication
          register_u2f_device
          logout

          # Try authenticating user with the old U2F device
          login_as(current_user)
          @u2f_device.respond_to_u2f_authentication
          click_on "Login Via U2F Device"
          expect(page.body).to match('We heard back from your U2F device')
          click_on "Authenticate via U2F Device"

          expect(page.body).to match('Authentication via U2F device failed')
        end
      end

      describe "and also the current user" do
        it "allows logging in with that particular device" do
          # Register current user with the same U2F device
          current_user = login_as(:user)
          current_user.update_attribute(:otp_required_for_login, true)
          visit profile_account_path
          manage_two_factor_authentication
          register_u2f_device(@u2f_device)
          logout

          # Try authenticating user with the same U2F device
          login_as(current_user)
          @u2f_device.respond_to_u2f_authentication
          click_on "Login Via U2F Device"
          expect(page.body).to match('We heard back from your U2F device')
          click_on "Authenticate via U2F Device"

          expect(page.body).to match('Signed in successfully')
        end
      end
    end

    describe "when a given U2F device has not been registered" do
      it "does not allow logging in with that particular device" do
        unregistered_device = FakeU2fDevice.new(page)
        login_as(user)
        unregistered_device.respond_to_u2f_authentication
        click_on "Login Via U2F Device"
        expect(page.body).to match('We heard back from your U2F device')
        click_on "Authenticate via U2F Device"

        expect(page.body).to match('Authentication via U2F device failed')
      end
    end

    describe "when more than one device has been registered by the same user" do
      it "allows logging in with either device" do
        # Register first device
        user = login_as(:user)
        user.update_attribute(:otp_required_for_login, true)
        visit profile_two_factor_auth_path
        expect(page).to have_content("Your U2F device needs to be set up.")
        first_device = register_u2f_device

        # Register second device
        visit profile_two_factor_auth_path
        expect(page).to have_content("Your U2F device needs to be set up.")
        second_device = register_u2f_device
        logout

        # Authenticate as both devices
        [first_device, second_device].each do |device|
          login_as(user)
          device.respond_to_u2f_authentication
          click_on "Login Via U2F Device"
          expect(page.body).to match('We heard back from your U2F device')
          click_on "Authenticate via U2F Device"

          expect(page.body).to match('Signed in successfully')

          logout
        end
      end
    end

    describe "when two-factor authentication is disabled" do
      let(:user) { create(:user) }

      before do
        user = login_as(:user)
        user.update_attribute(:otp_required_for_login, true)
        visit profile_account_path
        manage_two_factor_authentication
        expect(page).to have_content("Your U2F device needs to be set up.")
        register_u2f_device
      end

      it "deletes u2f registrations" do
        expect { click_on "Disable" }.to change { U2fRegistration.count }.by(-1)
      end
    end
  end
end
