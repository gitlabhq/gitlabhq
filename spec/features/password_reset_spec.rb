require 'spec_helper'

feature 'Password reset', feature: true do
  describe 'throttling' do
    it 'sends reset instructions when not previously sent' do
      visit root_path
      forgot_password(create(:user))

      expect(page).to have_content(I18n.t('devise.passwords.send_instructions'))
      expect(current_path).to eq new_user_session_path
    end

    it 'sends reset instructions when previously sent more than a minute ago' do
      user = create(:user)
      user.send_reset_password_instructions
      user.update_attribute(:reset_password_sent_at, 5.minutes.ago)

      visit root_path
      forgot_password(user)

      expect(page).to have_content(I18n.t('devise.passwords.send_instructions'))
      expect(current_path).to eq new_user_session_path
    end

    it "throttles multiple resets in a short timespan" do
      user = create(:user)
      user.send_reset_password_instructions

      visit root_path
      forgot_password(user)

      expect(page).to have_content("Instructions about how to reset your password have already been sent recently. Please wait a few minutes to try again.")
      expect(current_path).to eq new_user_password_path
    end
  end

  describe 'with two-factor authentication' do
    it 'requires login after password reset' do
      visit root_path

      forgot_password(create(:user, :two_factor))
      reset_password

      expect(page).to have_content("Your password was changed successfully.")
      expect(page).not_to have_content("You are now signed in.")
      expect(current_path).to eq new_user_session_path
    end
  end

  describe 'without two-factor authentication' do
    it 'requires login after password reset' do
      visit root_path

      forgot_password(create(:user))
      reset_password

      expect(page).to have_content("Your password was changed successfully.")
      expect(current_path).to eq new_user_session_path
    end
  end

  def forgot_password(user)
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
end
