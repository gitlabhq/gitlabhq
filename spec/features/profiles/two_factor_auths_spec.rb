# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Two factor auths' do
  context 'when signed in' do
    before do
      allow(Gitlab).to receive(:com?) { true }
    end

    context 'when user has two-factor authentication disabled' do
      let(:user) { create(:user ) }

      before do
        sign_in(user)
      end

      it 'requires the current password to set up two factor authentication', :js do
        visit profile_two_factor_auth_path

        register_2fa(user.reload.current_otp, '123')

        expect(page).to have_content('You must provide a valid current password')

        register_2fa(user.reload.current_otp, user.password)

        expect(page).to have_content('Please copy, download, or print your recovery codes before proceeding.')

        click_button 'Copy codes'
        click_link 'Proceed'

        expect(page).to have_content('Status: Enabled')
      end
    end

    context 'when user has two-factor authentication enabled' do
      let(:user) { create(:user, :two_factor) }

      before do
        sign_in(user)
      end

      it 'requires the current_password to disable two-factor authentication', :js do
        visit profile_two_factor_auth_path

        fill_in 'current_password', with: '123'

        click_button 'Disable two-factor authentication'

        page.accept_alert

        expect(page).to have_content('You must provide a valid current password')

        fill_in 'current_password', with: user.password

        click_button 'Disable two-factor authentication'

        page.accept_alert

        expect(page).to have_content('Two-factor authentication has been disabled successfully!')
        expect(page).to have_content('Enable two-factor authentication')
      end

      it 'requires the current_password to regernate recovery codes', :js do
        visit profile_two_factor_auth_path

        fill_in 'current_password', with: '123'

        click_button 'Regenerate recovery codes'

        expect(page).to have_content('You must provide a valid current password')

        fill_in 'current_password', with: user.password

        click_button 'Regenerate recovery codes'

        expect(page).to have_content('Please copy, download, or print your recovery codes before proceeding.')
      end
    end

    def register_2fa(pin, password)
      fill_in 'pin_code', with: pin
      fill_in 'current_password', with: password

      click_button 'Register with two-factor app'
    end
  end
end
