require 'spec_helper'

feature 'Password reset', feature: true do
  def forgot_password
    click_on 'Forgot your password?'
    fill_in 'Email', with: user.email
    click_button 'Reset password'
    user.reload
  end

  def get_reset_token
    mail = ActionMailer::Base.deliveries.last
    body = mail.body.encoded
    body.scan(/reset_password_token=(.+)\"/).flatten.first
  end

  def reset_password(password = 'password')
    visit edit_user_password_path(reset_password_token: get_reset_token)

    fill_in 'New password', with: password
    fill_in 'Confirm new password', with: password
    click_button 'Change your password'
  end

  describe 'with two-factor authentication' do
    let(:user) { create(:user, :two_factor) }

    it 'requires login after password reset' do
      visit root_path

      forgot_password
      reset_password

      expect(page).to have_content("Your password was changed successfully.")
      expect(page).not_to have_content("You are now signed in.")
      expect(current_path).to eq new_user_session_path
    end
  end

  describe 'without two-factor authentication' do
    let(:user) { create(:user) }

    it 'automatically logs in after password reset' do
      visit root_path

      forgot_password
      reset_password

      expect(current_path).to eq root_path
      expect(page).to have_content("Your password was changed successfully. You are now signed in.")
    end
  end
end
