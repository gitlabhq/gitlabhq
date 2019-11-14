# frozen_string_literal: true

require 'spec_helper'

shared_examples 'Signup' do
  include TermsHelper

  let(:new_user) { build_stubbed(:user) }

  describe 'username validation', :js do
    before do
      visit new_user_registration_path
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
      if Gitlab::Experimentation.enabled?(:signup_flow)
        user = create(:user, role: nil)
        sign_in(user)
        visit users_sign_up_welcome_path
        @user_name_field = 'user_name'
      else
        visit new_user_registration_path
        @user_name_field = 'new_user_name'
      end
    end

    it 'does not show an error border if the user\'s fullname length is not longer than 128 characters' do
      fill_in @user_name_field, with: 'u' * 128

      expect(find('.name')).not_to have_css '.gl-field-error-outline'
    end

    it 'shows an error border if the user\'s fullname contains an emoji' do
      simulate_input("##{@user_name_field}", 'Ehsan 🦋')

      expect(find('.name')).to have_css '.gl-field-error-outline'
    end

    it 'shows an error border if the user\'s fullname is longer than 128 characters' do
      fill_in @user_name_field, with: 'n' * 129

      expect(find('.name')).to have_css '.gl-field-error-outline'
    end

    it 'shows an error message if the user\'s fullname is longer than 128 characters' do
      fill_in @user_name_field, with: 'n' * 129

      expect(page).to have_content("Name is too long (maximum is 128 characters).")
    end

    it 'shows an error message if the username contains emojis' do
      simulate_input("##{@user_name_field}", 'Ehsan 🦋')

      expect(page).to have_content("Invalid input, please avoid emojis")
    end
  end

  context 'with no errors' do
    context 'when sending confirmation email' do
      before do
        stub_application_setting(send_user_confirmation_email: true)
      end

      context 'when soft email confirmation is not enabled' do
        before do
          stub_feature_flags(soft_email_confirmation: false)
        end

        it 'creates the user account and sends a confirmation email' do
          visit new_user_registration_path

          fill_in 'new_user_username', with: new_user.username
          fill_in 'new_user_email', with: new_user.email

          unless Gitlab::Experimentation.enabled?(:signup_flow)
            fill_in 'new_user_name', with: new_user.name
            fill_in 'new_user_email_confirmation', with: new_user.email
          end

          fill_in 'new_user_password', with: new_user.password

          expect { click_button 'Register' }.to change { User.count }.by(1)

          expect(current_path).to eq users_almost_there_path
          expect(page).to have_content('Please check your email to confirm your account')
        end
      end

      context 'when soft email confirmation is enabled' do
        before do
          stub_feature_flags(soft_email_confirmation: true)
        end

        it 'creates the user account and sends a confirmation email' do
          visit new_user_registration_path

          fill_in 'new_user_username', with: new_user.username
          fill_in 'new_user_email', with: new_user.email

          unless Gitlab::Experimentation.enabled?(:signup_flow)
            fill_in 'new_user_name', with: new_user.name
            fill_in 'new_user_email_confirmation', with: new_user.email
          end

          fill_in 'new_user_password', with: new_user.password

          expect { click_button 'Register' }.to change { User.count }.by(1)

          if Gitlab::Experimentation.enabled?(:signup_flow)
            expect(current_path).to eq users_sign_up_welcome_path
          else
            expect(current_path).to eq dashboard_projects_path
            expect(page).to have_content("Please check your email (#{new_user.email}) to verify that you own this address and unlock the power of CI/CD.")
          end
        end
      end
    end

    context "when sigining up with different cased emails" do
      it "creates the user successfully" do
        visit new_user_registration_path

        fill_in 'new_user_username', with: new_user.username
        fill_in 'new_user_email', with: new_user.email

        unless Gitlab::Experimentation.enabled?(:signup_flow)
          fill_in 'new_user_name', with: new_user.name
          fill_in 'new_user_email_confirmation', with: new_user.email.capitalize
        end

        fill_in 'new_user_password', with: new_user.password
        click_button "Register"

        if Gitlab::Experimentation.enabled?(:signup_flow)
          expect(current_path).to eq users_sign_up_welcome_path
        else
          expect(current_path).to eq dashboard_projects_path
          expect(page).to have_content("Welcome! You have signed up successfully.")
        end
      end
    end

    context "when not sending confirmation email" do
      before do
        stub_application_setting(send_user_confirmation_email: false)
      end

      it 'creates the user account and goes to dashboard' do
        visit new_user_registration_path

        fill_in 'new_user_username', with: new_user.username
        fill_in 'new_user_email', with: new_user.email

        unless Gitlab::Experimentation.enabled?(:signup_flow)
          fill_in 'new_user_name', with: new_user.name
          fill_in 'new_user_email_confirmation', with: new_user.email
        end

        fill_in 'new_user_password', with: new_user.password
        click_button "Register"

        if Gitlab::Experimentation.enabled?(:signup_flow)
          expect(current_path).to eq users_sign_up_welcome_path
        else
          expect(current_path).to eq dashboard_projects_path
          expect(page).to have_content("Welcome! You have signed up successfully.")
        end
      end
    end
  end

  context 'with errors' do
    it "displays the errors" do
      existing_user = create(:user)

      visit new_user_registration_path

      unless Gitlab::Experimentation.enabled?(:signup_flow)
        fill_in 'new_user_name', with: new_user.name
      end

      fill_in 'new_user_username', with: new_user.username
      fill_in 'new_user_email', with: existing_user.email
      fill_in 'new_user_password', with: new_user.password
      click_button "Register"

      expect(current_path).to eq user_registration_path

      if Gitlab::Experimentation.enabled?(:signup_flow)
        expect(page).to have_content("error prohibited this user from being saved")
      else
        expect(page).to have_content("errors prohibited this user from being saved")
        expect(page).to have_content("Email confirmation doesn't match")
      end

      expect(page).to have_content("Email has already been taken")
    end

    it 'does not redisplay the password' do
      existing_user = create(:user)

      visit new_user_registration_path

      unless Gitlab::Experimentation.enabled?(:signup_flow)
        fill_in 'new_user_name', with: new_user.name
      end

      fill_in 'new_user_username', with: new_user.username
      fill_in 'new_user_email', with: existing_user.email
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
      visit new_user_registration_path

      fill_in 'new_user_username', with: new_user.username
      fill_in 'new_user_email', with: new_user.email

      unless Gitlab::Experimentation.enabled?(:signup_flow)
        fill_in 'new_user_name', with: new_user.name
        fill_in 'new_user_email_confirmation', with: new_user.email
      end

      fill_in 'new_user_password', with: new_user.password

      click_button 'Register'

      expect(current_path).to eq new_user_session_path
      expect(page).to have_content(/you must accept our terms of service/i)
    end

    it 'asks the user to accept terms before going to the dashboard' do
      visit new_user_registration_path

      fill_in 'new_user_username', with: new_user.username
      fill_in 'new_user_email', with: new_user.email

      unless Gitlab::Experimentation.enabled?(:signup_flow)
        fill_in 'new_user_name', with: new_user.name
        fill_in 'new_user_email_confirmation', with: new_user.email
      end

      fill_in 'new_user_password', with: new_user.password
      check :terms_opt_in

      click_button "Register"

      if Gitlab::Experimentation.enabled?(:signup_flow)
        expect(current_path).to eq users_sign_up_welcome_path
      else
        expect(current_path).to eq dashboard_projects_path
      end
    end
  end

  context 'when reCAPTCHA and invisible captcha are enabled' do
    before do
      InvisibleCaptcha.timestamp_enabled = true
      stub_application_setting(recaptcha_enabled: true)
      allow_next_instance_of(RegistrationsController) do |instance|
        allow(instance).to receive(:verify_recaptcha).and_return(false)
      end
    end

    after do
      InvisibleCaptcha.timestamp_enabled = false
    end

    it 'prevents from signing up' do
      visit new_user_registration_path

      fill_in 'new_user_username', with: new_user.username
      fill_in 'new_user_email', with: new_user.email

      unless Gitlab::Experimentation.enabled?(:signup_flow)
        fill_in 'new_user_name', with: new_user.name
        fill_in 'new_user_email_confirmation', with: new_user.email
      end

      fill_in 'new_user_password', with: new_user.password

      expect { click_button 'Register' }.not_to change { User.count }

      if Gitlab::Experimentation.enabled?(:signup_flow)
        expect(page).to have_content('That was a bit too quick! Please resubmit.')
      else
        expect(page).to have_content('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.')
      end
    end
  end
end

describe 'With original flow' do
  before do
    stub_experiment(signup_flow: false)
    stub_experiment_for_user(signup_flow: false)
  end

  it_behaves_like 'Signup'
end

describe 'With experimental flow' do
  before do
    stub_experiment(signup_flow: true)
    stub_experiment_for_user(signup_flow: true)
  end

  it_behaves_like 'Signup'

  describe 'when role is required' do
    it 'after registering, it redirects to step 2 of the signup process, sets the name and role and then redirects to the original requested url' do
      new_user = build_stubbed(:user)
      visit new_user_registration_path
      fill_in 'new_user_username', with: new_user.username
      fill_in 'new_user_email', with: new_user.email
      fill_in 'new_user_password', with: new_user.password
      click_button 'Register'
      visit new_project_path

      expect(page).to have_current_path(users_sign_up_welcome_path)

      fill_in 'user_name', with: 'New name'
      select 'Software Developer', from: 'user_role'
      choose 'user_setup_for_company_true'
      click_button 'Get started!'
      new_user = User.find_by_username(new_user.username)

      expect(new_user.name).to eq 'New name'
      expect(new_user.software_developer_role?).to be_truthy
      expect(new_user.setup_for_company).to be_truthy
      expect(page).to have_current_path(new_project_path)
    end
  end
end
