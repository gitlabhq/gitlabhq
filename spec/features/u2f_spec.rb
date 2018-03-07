require 'spec_helper'

feature 'Using U2F (Universal 2nd Factor) Devices for Authentication', :js do
  def manage_two_factor_authentication
    click_on 'Manage two-factor authentication'
    expect(page).to have_content("Setup new U2F device")
    wait_for_requests
  end

  def register_u2f_device(u2f_device = nil, name: 'My device')
    u2f_device ||= FakeU2fDevice.new(page, name)
    u2f_device.respond_to_u2f_registration
    click_on 'Setup new U2F device'
    expect(page).to have_content('Your device was successfully set up')
    fill_in "Pick a name", with: name
    click_on 'Register U2F device'
    u2f_device
  end

  describe "registration" do
    let(:user) { create(:user) }

    before do
      gitlab_sign_in(user)
      user.update_attribute(:otp_required_for_login, true)
    end

    describe 'when 2FA via OTP is disabled' do
      before do
        user.update_attribute(:otp_required_for_login, false)
      end

      it 'does not allow registering a new device' do
        visit profile_account_path
        click_on 'Enable two-factor authentication'

        expect(page).to have_button('Setup new U2F device', disabled: true)
      end
    end

    describe 'when 2FA via OTP is enabled' do
      it 'allows registering a new device with a name' do
        visit profile_account_path
        manage_two_factor_authentication
        expect(page).to have_content("You've already enabled two-factor authentication using mobile")

        u2f_device = register_u2f_device

        expect(page).to have_content(u2f_device.name)
        expect(page).to have_content('Your U2F device was registered')
      end

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

      it 'allows deleting a device' do
        visit profile_account_path
        manage_two_factor_authentication
        expect(page).to have_content("You've already enabled two-factor authentication using mobile")

        first_u2f_device = register_u2f_device
        second_u2f_device = register_u2f_device(name: 'My other device')

        accept_confirm { click_on "Delete", match: :first }

        expect(page).to have_content('Successfully deleted')
        expect(page.body).not_to match(first_u2f_device.name)
        expect(page).to have_content(second_u2f_device.name)
      end
    end

    it 'allows the same device to be registered for multiple users' do
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
        click_on 'Setup new U2F device'
        expect(page).to have_content('Your device was successfully set up')
        click_on 'Register U2F device'

        expect(U2fRegistration.count).to eq(0)
        expect(page).to have_content("The form contains the following error")
        expect(page).to have_content("did not send a valid JSON response")
      end

      it "allows retrying registration" do
        visit profile_account_path
        manage_two_factor_authentication

        # Failed registration
        page.execute_script("u2f.register = function(_,_,_,callback) { callback('bad response'); };")
        click_on 'Setup new U2F device'
        expect(page).to have_content('Your device was successfully set up')
        click_on 'Register U2F device'
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
        expect(page).to have_content("Your U2F device needs to be set up.")
        first_device = register_u2f_device

        # Register second device
        visit profile_two_factor_auth_path
        expect(page).to have_content("Your U2F device needs to be set up.")
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

    describe "when two-factor authentication is disabled" do
      let(:user) { create(:user) }

      before do
        user = gitlab_sign_in(:user)
        user.update_attribute(:otp_required_for_login, true)
        visit profile_account_path
        manage_two_factor_authentication
        expect(page).to have_content("Your U2F device needs to be set up.")
        register_u2f_device
      end

      it "deletes u2f registrations" do
        visit profile_two_factor_auth_path
        expect do
          accept_confirm { click_on "Disable" }
        end.to change { U2fRegistration.count }.by(-1)
      end
    end
  end

  describe 'fallback code authentication' do
    let(:user) { create(:user) }

    def assert_fallback_ui(page)
      expect(page).to have_button('Verify code')
      expect(page).to have_css('#user_otp_attempt')
      expect(page).not_to have_link('Sign in via 2FA code')
      expect(page).not_to have_css('#js-authenticate-u2f')
    end

    before do
      # Register and logout
      gitlab_sign_in(user)
      user.update_attribute(:otp_required_for_login, true)
      visit profile_account_path
    end

    describe 'when no u2f device is registered' do
      before do
        gitlab_sign_out
        gitlab_sign_in(user)
      end

      it 'shows the fallback otp code UI' do
        assert_fallback_ui(page)
      end
    end

    describe 'when a u2f device is registered' do
      before do
        manage_two_factor_authentication
        @u2f_device = register_u2f_device
        gitlab_sign_out
        gitlab_sign_in(user)
      end

      it 'provides a button that shows the fallback otp code UI' do
        expect(page).to have_link('Sign in via 2FA code')

        click_link('Sign in via 2FA code')

        assert_fallback_ui(page)
      end
    end
  end
end
