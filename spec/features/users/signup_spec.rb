require 'spec_helper'

describe 'Signup' do
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
      fill_in 'new_user_username', with: 'new.user.username'
      wait_for_requests

      expect(find('.username')).not_to have_css '.gl-field-error-outline'
    end

    it 'shows an error border if the username already exists' do
      existing_user = create(:user)

      fill_in 'new_user_username', with: existing_user.username
      wait_for_requests

      expect(find('.username')).to have_css '.gl-field-error-outline'
    end

    it 'shows an  error border if the username contains special characters' do
      fill_in 'new_user_username', with: 'new$user!username'
      wait_for_requests

      expect(find('.username')).to have_css '.gl-field-error-outline'
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
end
