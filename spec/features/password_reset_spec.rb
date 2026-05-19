# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Password reset', feature_category: :system_access do
  describe 'throttling', :js do
    before do
      stub_current_organization(create(:organization))
    end

    it 'sends reset instructions when not previously sent' do
      user = create(:user)
      forgot_password(user)

      expect(page).to have_content(I18n.t('devise.passwords.send_paranoid_instructions'))
      expect(page).to have_current_path new_user_session_path, ignore_query: true
      expect(user.reload.recently_sent_password_reset?).to be_truthy
    end

    it 'sends reset instructions when previously sent more than a minute ago' do
      user = create(:user)
      user.send_reset_password_instructions
      user.update_attribute(:reset_password_sent_at, 5.minutes.ago)

      expect do
        forgot_password(user)

        expect(page).to have_content(I18n.t('devise.passwords.send_paranoid_instructions'))
        expect(page).to have_current_path new_user_session_path, ignore_query: true
      end.to change { user.reload.reset_password_sent_at }
    end

    it 'throttles multiple resets in a short timespan' do
      user = create(:user)
      user.send_reset_password_instructions
      # Reload because PG handles datetime less precisely than Ruby/Rails
      user.reload

      expect do
        forgot_password(user)

        expect(page).to have_content(I18n.t('devise.passwords.send_paranoid_instructions'))
        expect(page).to have_current_path new_user_session_path, ignore_query: true
      end.not_to change { user.reload.reset_password_sent_at }
    end
  end

  describe 'Changing password while logged in' do
    it 'updates the password' do
      user = create(:user)
      token = user.send_reset_password_instructions

      sign_in(user)

      visit(edit_user_password_path(reset_password_token: token))

      fill_in 'New password', with: 'hello1234'
      fill_in 'Confirm new password', with: 'hello1234'

      click_button 'Change your password'

      expect(page).to have_content(I18n.t('devise.passwords.updated_not_active'))
      expect(page).to have_current_path new_user_session_path, ignore_query: true
    end
  end

  def forgot_password(user)
    visit root_path
    click_on 'Forgot your password?'
    fill_in 'Email', with: user.email
    click_button 'Reset password'
  end
end
