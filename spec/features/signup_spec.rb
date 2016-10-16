require 'spec_helper'

feature 'Signup', feature: true do
  describe 'signup with no errors' do
    context "when sending confirmation email" do
      before { allow_any_instance_of(ApplicationSetting).to receive(:send_user_confirmation_email).and_return(true) }

      it 'creates the user account and sends a confirmation email' do
        user = build(:user)

        visit root_path

        fill_in 'new_user_name',     with: user.name
        fill_in 'new_user_username', with: user.username
        fill_in 'new_user_email',    with: user.email
        fill_in 'new_user_password', with: user.password
        click_button "Register"

        expect(current_path).to eq users_almost_there_path
        expect(page).to have_content("Please check your email to confirm your account")
      end
    end

    context "when not sending confirmation email" do
      before { allow_any_instance_of(ApplicationSetting).to receive(:send_user_confirmation_email).and_return(false) }

      it 'creates the user account and goes to dashboard' do
        user = build(:user)

        visit root_path

        fill_in 'new_user_name',     with: user.name
        fill_in 'new_user_username', with: user.username
        fill_in 'new_user_email',    with: user.email
        fill_in 'new_user_password', with: user.password
        click_button "Register"

        expect(current_path).to eq dashboard_projects_path
        expect(page).to have_content("Welcome! You have signed up successfully.")
      end
    end
  end

  describe 'signup with errors' do
    it "displays the errors" do
      existing_user = create(:user)
      user = build(:user)

      visit root_path

      fill_in 'new_user_name',     with: user.name
      fill_in 'new_user_username', with: user.username
      fill_in 'new_user_email',    with: existing_user.email
      fill_in 'new_user_password', with: user.password
      click_button "Register"

      expect(current_path).to eq user_registration_path
      expect(page).to have_content("error prohibited this user from being saved")
      expect(page).to have_content("Email has already been taken")
    end

    it 'does not redisplay the password' do
      existing_user = create(:user)
      user = build(:user)

      visit root_path

      fill_in 'new_user_name',     with: user.name
      fill_in 'new_user_username', with: user.username
      fill_in 'new_user_email',    with: existing_user.email
      fill_in 'new_user_password', with: user.password
      click_button "Register"

      expect(current_path).to eq user_registration_path
      expect(page.body).not_to match(/#{user.password}/)
    end
  end
end
