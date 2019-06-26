require 'spec_helper'

describe 'Signup' do
  include TermsHelper

  let(:new_user) { build_stubbed(:user) }

  describe 'username validation', :js do
    before do
      visit root_path
      click_link 'Register'
    end

    it 'does not show an error border if the username is available' do
      fill_in 'new_user_username', with: 'new-user'
      wait_for_requests

      expect(find('.username')).not_to have_css '.gl-field-error-outline'
    end

    it 'does not show an error border if the username contains dots (.)' do
      simulate_input('#new_user_username', 'new.user.username')
      wait_for_requests

      expect(find('.username')).not_to have_css '.gl-field-error-outline'
    end

    it 'does not show an error border if the username length is not longer than 255 characters' do
      fill_in 'new_user_username', with: 'u' * 255
      wait_for_requests

      expect(find('.username')).not_to have_css '.gl-field-error-outline'
    end

    it 'shows an error border if the username already exists' do
      existing_user = create(:user)

      fill_in 'new_user_username', with: existing_user.username
      wait_for_requests

      expect(find('.username')).to have_css '.gl-field-error-outline'
    end

    it 'shows a success border if the username is available' do
      fill_in 'new_user_username', with: 'new-user'
      wait_for_requests

      expect(find('.username')).to have_css '.gl-field-success-outline'
    end

    it 'shows an error border if the username contains special characters' do
      fill_in 'new_user_username', with: 'new$user!username'
      wait_for_requests

      expect(find('.username')).to have_css '.gl-field-error-outline'
    end

    it 'shows an error border if the username is longer than 255 characters' do
      fill_in 'new_user_username', with: 'u' * 256
      wait_for_requests

      expect(find('.username')).to have_css '.gl-field-error-outline'
    end

    it 'shows an error message if the username is longer than 255 characters' do
      fill_in 'new_user_username', with: 'u' * 256
      wait_for_requests

      expect(page).to have_content("Username is too long (maximum is 255 characters).")
    end

    it 'shows an error message on submit if the username contains special characters' do
      fill_in 'new_user_username', with: 'new$user!username'
      wait_for_requests

      click_button "Register"

      expect(page).to have_content("Please create a username with only alphanumeric characters.")
    end

    it 'shows an error border if the username contains emojis' do
      simulate_input('#new_user_username', 'ehsan😀')

      expect(find('.username')).to have_css '.gl-field-error-outline'
    end

    it 'shows an error message if the username contains emojis' do
      simulate_input('#new_user_username', 'ehsan😀')

      expect(page).to have_content("Invalid input, please avoid emojis")
    end

    it 'shows a pending message if the username availability is being fetched', :quarantine do
      fill_in 'new_user_username', with: 'new-user'

      expect(find('.username > .validation-pending')).not_to have_css '.hide'
    end

    it 'shows a success message if the username is available' do
      fill_in 'new_user_username', with: 'new-user'
      wait_for_requests

      expect(find('.username > .validation-success')).not_to have_css '.hide'
    end

    it 'shows an error message if the username is unavailable' do
      existing_user = create(:user)

      fill_in 'new_user_username', with: existing_user.username
      wait_for_requests

      expect(find('.username > .validation-error')).not_to have_css '.hide'
    end

    it 'shows a success message if the username is corrected and then available' do
      fill_in 'new_user_username', with: 'new-user$'
      wait_for_requests
      fill_in 'new_user_username', with: 'new-user'
      wait_for_requests

      expect(page).to have_content("Username is available.")
    end
  end

  describe 'user\'s full name validation', :js do
    before do
      visit root_path
      click_link 'Register'
    end

    it 'does not show an error border if the user\'s fullname length is not longer than 128 characters' do
      fill_in 'new_user_name', with: 'u' * 128

      expect(find('.name')).not_to have_css '.gl-field-error-outline'
    end

    it 'shows an error border if the user\'s fullname contains an emoji' do
      simulate_input('#new_user_name', 'Ehsan 🦋')

      expect(find('.name')).to have_css '.gl-field-error-outline'
    end

    it 'shows an error border if the user\'s fullname is longer than 128 characters' do
      fill_in 'new_user_name', with: 'n' * 129

      expect(find('.name')).to have_css '.gl-field-error-outline'
    end

    it 'shows an error message if the user\'s fullname is longer than 128 characters' do
      fill_in 'new_user_name', with: 'n' * 129

      expect(page).to have_content("Name is too long (maximum is 128 characters).")
    end

    it 'shows an error message if the username contains emojis' do
      simulate_input('#new_user_name', 'Ehsan 🦋')

      expect(page).to have_content("Invalid input, please avoid emojis")
    end
  end

  context 'with no errors' do
    context "when sending confirmation email" do
      before do
        stub_application_setting(send_user_confirmation_email: true)
      end

      it 'creates the user account and sends a confirmation email' do
        visit root_path

        fill_in 'new_user_name',                with: new_user.name
        fill_in 'new_user_username',            with: new_user.username
        fill_in 'new_user_email',               with: new_user.email
        fill_in 'new_user_email_confirmation',  with: new_user.email
        fill_in 'new_user_password',            with: new_user.password

        expect { click_button 'Register' }.to change { User.count }.by(1)

        expect(current_path).to eq users_almost_there_path
        expect(page).to have_content("Please check your email to confirm your account")
      end
    end

    context "when sigining up with different cased emails" do
      it "creates the user successfully" do
        visit root_path

        fill_in 'new_user_name',                with: new_user.name
        fill_in 'new_user_username',            with: new_user.username
        fill_in 'new_user_email',               with: new_user.email
        fill_in 'new_user_email_confirmation',  with: new_user.email.capitalize
        fill_in 'new_user_password',            with: new_user.password
        click_button "Register"

        expect(current_path).to eq dashboard_projects_path
        expect(page).to have_content("Welcome! You have signed up successfully.")
      end
    end

    context "when not sending confirmation email" do
      before do
        stub_application_setting(send_user_confirmation_email: false)
      end

      it 'creates the user account and goes to dashboard' do
        visit root_path

        fill_in 'new_user_name',                with: new_user.name
        fill_in 'new_user_username',            with: new_user.username
        fill_in 'new_user_email',               with: new_user.email
        fill_in 'new_user_email_confirmation',  with: new_user.email
        fill_in 'new_user_password',            with: new_user.password
        click_button "Register"

        expect(current_path).to eq dashboard_projects_path
        expect(page).to have_content("Welcome! You have signed up successfully.")
      end
    end
  end

  context 'with errors' do
    it "displays the errors" do
      existing_user = create(:user)

      visit root_path

      fill_in 'new_user_name',     with: new_user.name
      fill_in 'new_user_username', with: new_user.username
      fill_in 'new_user_email',    with: existing_user.email
      fill_in 'new_user_password', with: new_user.password
      click_button "Register"

      expect(current_path).to eq user_registration_path
      expect(page).to have_content("errors prohibited this user from being saved")
      expect(page).to have_content("Email has already been taken")
      expect(page).to have_content("Email confirmation doesn't match")
    end

    it 'does not redisplay the password' do
      existing_user = create(:user)

      visit root_path

      fill_in 'new_user_name',     with: new_user.name
      fill_in 'new_user_username', with: new_user.username
      fill_in 'new_user_email',    with: existing_user.email
      fill_in 'new_user_password', with: new_user.password
      click_button "Register"

      expect(current_path).to eq user_registration_path
      expect(page.body).not_to match(/#{new_user.password}/)
    end
  end

  context 'when terms are enforced' do
    before do
      enforce_terms
    end

    it 'requires the user to check the checkbox' do
      visit root_path

      fill_in 'new_user_name',                with: new_user.name
      fill_in 'new_user_username',            with: new_user.username
      fill_in 'new_user_email',               with: new_user.email
      fill_in 'new_user_email_confirmation',  with: new_user.email
      fill_in 'new_user_password',            with: new_user.password

      click_button 'Register'

      expect(current_path).to eq new_user_session_path
      expect(page).to have_content(/you must accept our terms of service/i)
    end

    it 'asks the user to accept terms before going to the dashboard' do
      visit root_path

      fill_in 'new_user_name',                with: new_user.name
      fill_in 'new_user_username',            with: new_user.username
      fill_in 'new_user_email',               with: new_user.email
      fill_in 'new_user_email_confirmation',  with: new_user.email
      fill_in 'new_user_password',            with: new_user.password
      check :terms_opt_in

      click_button "Register"

      expect(current_path).to eq dashboard_projects_path
    end
  end
end
