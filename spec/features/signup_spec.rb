require 'spec_helper'

feature 'Signup', feature: true do
  describe 'signup with no errors' do
    it 'creates the user account and sends a confirmation email' do
      user = build(:user)

      visit root_path

      fill_in 'user_name',                with: user.name
      fill_in 'user_username',            with: user.username
      fill_in 'user_email',               with: user.email
      fill_in 'user_password_sign_up',    with: user.password
      click_button "Sign up"

      expect(current_path).to eq user_session_path
      expect(page).to have_content("A message with a confirmation link has been sent to your email address.")
    end
  end

  describe 'signup with errors' do
    it "displays the errors" do
      existing_user = create(:user)
      user = build(:user)

      visit root_path

      fill_in 'user_name',                with: user.name
      fill_in 'user_username',            with: user.username
      fill_in 'user_email',               with: existing_user.email
      fill_in 'user_password_sign_up',    with: user.password
      click_button "Sign up"

      expect(current_path).to eq user_registration_path
      expect(page).to have_content("error prohibited this user from being saved")
      expect(page).to have_content("Email has already been taken")
    end

    it 'does not redisplay the password' do
      existing_user = create(:user)
      user = build(:user)

      visit root_path

      fill_in 'user_name',                with: user.name
      fill_in 'user_username',            with: user.username
      fill_in 'user_email',               with: existing_user.email
      fill_in 'user_password_sign_up',    with: user.password
      click_button "Sign up"

      expect(current_path).to eq user_registration_path
      expect(page.body).not_to match(/#{user.password}/)
    end
  end
end
