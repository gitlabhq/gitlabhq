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

      expect(page).to have_content(I18n.t('devise.passwords.recently_reset'))
      expect(current_path).to eq new_user_password_path
    end
  end

  def forgot_password(user)
    click_on 'Forgot your password?'
    fill_in 'Email', with: user.email
    click_button 'Reset password'
    user.reload
  end
end
