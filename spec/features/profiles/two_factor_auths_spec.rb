# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Two factor auths', feature_category: :system_access do
  include Spec::Support::Helpers::ModalHelpers

  context 'when signed in' do
    let(:invalid_current_pwd_msg) { 'You must provide a valid current password' }

    before do
      sign_in(user)
    end

    context 'when user has two-factor authentication disabled' do
      let_it_be(:user) { create(:user) }

      it 'requires the current password to set up two factor authentication', :js do
        visit profile_two_factor_auth_path

        register_2fa(user.current_otp, '123')

        expect(page).to have_selector('.gl-alert-title', text: invalid_current_pwd_msg, count: 1)

        register_2fa(user.reload.current_otp, user.password)

        expect(page).to have_content('Please copy, download, or print your recovery codes before proceeding.')

        click_button 'Copy codes'
        click_link 'Proceed'

        expect(page).to have_content('Status: Enabled')
      end

      context 'when user authenticates with an external service' do
        let_it_be(:user) { create(:omniauth_user) }

        it 'does not require the current password to set up two factor authentication', :js do
          visit profile_two_factor_auth_path

          fill_in 'pin_code', with: user.current_otp
          click_button 'Register with two-factor app'

          expect(page).to have_content('Please copy, download, or print your recovery codes before proceeding.')

          click_button 'Copy codes'
          click_link 'Proceed'

          expect(page).to have_content('Status: Enabled')
        end
      end

      context 'when invalid pin is provided' do
        let_it_be(:user) { create(:omniauth_user) }

        it 'renders a error alert with a link to the troubleshooting section' do
          visit profile_two_factor_auth_path

          fill_in 'pin_code', with: '123'
          click_button 'Register with two-factor app'

          expect(page).to have_link('Try the troubleshooting steps here.', href: help_page_path('user/profile/account/two_factor_authentication', anchor: 'troubleshooting'))
        end
      end

      context 'when two factor is enforced for administrator users' do
        let_it_be(:admin) { create(:admin) }

        before do
          stub_application_setting(require_admin_two_factor_authentication: require_admin_two_factor_authentication)
          sign_in(admin)
        end

        context 'when visiting root dashboard path' do
          let(:require_admin_two_factor_authentication) { true }

          it 'renders alert for administrator users' do
            visit profile_two_factor_auth_path
            expect(page).to have_content('Administrator users are required to enable Two-Factor Authentication for their account. You need to do this before ')
          end
        end
      end

      context 'when two factor is disabled for administrator users' do
        context 'when visiting root dashboard path' do
          let(:require_admin_two_factor_authentication) { false }

          it 'does not render an alert for administrator users' do
            visit profile_two_factor_auth_path
            expect(page).not_to have_content('Administrator users are required to enable Two-Factor Authentication for their account. You need to do this before ')
          end
        end
      end

      context 'when two factor is enforced in global settings' do
        before do
          stub_application_setting(require_two_factor_authentication: true)
        end

        context 'when invalid pin is provided' do
          let_it_be(:user) { create(:omniauth_user) }

          it 'renders alert for global settings' do
            visit profile_two_factor_auth_path

            fill_in 'pin_code', with: '123'
            click_button 'Register with two-factor app'

            expect(page).to have_content('The global settings require you to enable Two-Factor Authentication for your account. You need to do this before ')
          end
        end

        context 'when invalid password is provided' do
          let_it_be(:user) { create(:user) }

          it 'renders a error alert with a link to the troubleshooting section' do
            visit profile_two_factor_auth_path

            register_2fa(user.current_otp, 'abc')
            click_button 'Register with two-factor app'

            expect(page).to have_content(
              'The global settings require you to enable Two-Factor Authentication for your account'
            )
          end
        end
      end
    end

    context 'when user has two-factor authentication enabled' do
      let_it_be(:user) { create(:user, :two_factor) }

      it 'requires the current_password to disable two-factor authentication', :js do
        visit profile_two_factor_auth_path

        fill_in 'current_password', with: '123'

        click_button 'Disable two-factor authentication'

        within_modal do
          click_button 'Disable'
        end

        expect(page).to have_selector('.gl-alert-title', text: invalid_current_pwd_msg, count: 1)

        fill_in 'current_password', with: user.password

        click_button 'Disable two-factor authentication'

        within_modal do
          click_button 'Disable'
        end

        expect(page).to have_content('Two-factor authentication has been disabled successfully!')
        expect(page).to have_content('Enable two-factor authentication')
      end

      it 'requires the current_password to regenerate recovery codes', :js do
        visit profile_two_factor_auth_path

        fill_in 'current_password', with: '123'

        click_button 'Regenerate recovery codes'

        expect(page).to have_selector('.gl-alert-title', text: invalid_current_pwd_msg, count: 1)

        fill_in 'current_password', with: user.password

        click_button 'Regenerate recovery codes'

        expect(page).to have_content('Please copy, download, or print your recovery codes before proceeding.')
      end

      context 'when user authenticates with an external service' do
        let_it_be(:user) { create(:omniauth_user, :two_factor) }

        it 'does not require the current_password to disable two-factor authentication', :js do
          visit profile_two_factor_auth_path

          click_button 'Disable two-factor authentication'

          within_modal do
            click_button 'Disable'
          end

          expect(page).to have_content('Two-factor authentication has been disabled successfully!')
          expect(page).to have_content('Enable two-factor authentication')
        end

        it 'does not require the current_password to regenerate recovery codes', :js do
          visit profile_two_factor_auth_path

          click_button 'Regenerate recovery codes'

          expect(page).to have_content('Please copy, download, or print your recovery codes before proceeding.')
        end
      end
    end

    def register_2fa(pin, password)
      fill_in 'pin_code', with: pin
      fill_in 'current_password', with: password

      click_button 'Register with two-factor app'
    end
  end
end
