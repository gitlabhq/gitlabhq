require 'spec_helper'

feature 'Password reset', feature: true do
  describe 'throttling' do
    it 'sends reset instructions when not previously sent' do
      user = create(:user)
      forgot_password(user)

      expect(page).to have_content(I18n.t('devise.passwords.send_paranoid_instructions'))
      expect(current_path).to eq new_user_session_path
      expect(user.recently_sent_password_reset?).to be_truthy
    end

    it 'sends reset instructions when previously sent more than a minute ago' do
      user = create(:user)
      user.send_reset_password_instructions
      user.update_attribute(:reset_password_sent_at, 5.minutes.ago)

      expect{ forgot_password(user) }.to change{ user.reset_password_sent_at }
      expect(page).to have_content(I18n.t('devise.passwords.send_paranoid_instructions'))
      expect(current_path).to eq new_user_session_path
    end

    it 'throttles multiple resets in a short timespan' do
      user = create(:user)
      user.send_reset_password_instructions
      # Reload because PG handles datetime less precisely than Ruby/Rails
      user.reload

      expect{ forgot_password(user) }.not_to change{ user.reset_password_sent_at }
      expect(page).to have_content(I18n.t('devise.passwords.send_paranoid_instructions'))
      expect(current_path).to eq new_user_session_path
    end
  end

  def forgot_password(user)
    visit root_path
    click_on 'Forgot your password?'
    fill_in 'Email', with: user.email
    click_button 'Reset password'
    user.reload
  end
end
