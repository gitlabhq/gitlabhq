# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Two factor auths', feature_category: :system_access do
  include Spec::Support::Helpers::ModalHelpers
  include Features::TwoFactorHelpers

  context 'when signed in' do
    let(:current_organization) { user.organization }
    let(:invalid_current_pwd_msg) { 'You must provide a valid current password.' }

    before do
      sign_in(user)
    end

    context 'when user has two-factor authentication disabled' do
      let_it_be(:user) { create(:user) }

      it 'requires the current password to set up two factor authentication', :js do
        visit profile_two_factor_auth_path

        otp_authenticator_registration(user.current_otp, '123')

        expect(page).to have_selector('.gl-alert-title', text: invalid_current_pwd_msg, count: 1)

        otp_authenticator_registration(user.reload.current_otp, user.password)

        expect(page).to have_content('Please copy, download, or print your recovery codes before proceeding.')

        click_button 'Copy codes'
        click_link 'Proceed'

        expect(page).to have_text(_('2FA setup complete!'))
      end

      context 'when user authenticates with an external service' do
        let_it_be(:user) { create(:omniauth_user) }

        it 'does not require the current password to set up two factor authentication', :js do
          visit profile_two_factor_auth_path

          otp_authenticator_registration(user.current_otp)

          expect(page).to have_content('Please copy, download, or print your recovery codes before proceeding.')

          click_button 'Copy codes'
          click_link 'Proceed'

          expect(page).to have_text(_('2FA setup complete!'))
        end
      end

      context 'when invalid pin is provided' do
        let_it_be(:user) { create(:omniauth_user) }

        it 'renders a error alert with a link to the troubleshooting section' do
          visit profile_two_factor_auth_path

          otp_authenticator_registration('123')

          expect(page).to have_link('Try the troubleshooting steps here.', href: help_page_path('user/profile/account/two_factor_authentication_troubleshooting.md'))
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

        context 'when a grace period is set' do
          before do
            stub_application_setting(two_factor_grace_period: 24.hours)
          end

          it 'allows the user to skip enabling within the grace period' do
            visit root_path

            expect(page).to have_current_path(profile_two_factor_auth_path, ignore_query: true)

            click_link _('Configure it later')

            expect(page).to have_current_path(root_path)
          end
        end

        context 'when invalid pin is provided' do
          let_it_be(:user) { create(:omniauth_user) }

          it 'renders alert for global settings' do
            visit profile_two_factor_auth_path

            otp_authenticator_registration('123')

            expect(page).to have_content('The global settings require you to enable Two-Factor Authentication for your account. You need to do this before ')
          end
        end

        context 'when invalid password is provided' do
          let_it_be(:user) { create(:user) }

          it 'renders a error alert with a link to the troubleshooting section' do
            visit profile_two_factor_auth_path

            otp_authenticator_registration(user.current_otp, 'abc')
            click_button 'Register with two-factor app'

            expect(page).to have_content(
              'The global settings require you to enable Two-Factor Authentication for your account'
            )
          end
        end

        context 'when only email-based OTP is enabled' do
          let(:user) { create(:user, email_otp_required_after: 1.day.ago) }

          it 'does not accept it as 2FA' do
            visit root_path

            # to confirm that the user has enabled email_otp
            expect(user.user_detail.email_otp_required_after).not_to be_nil

            expect(page).to have_current_path(profile_two_factor_auth_path, ignore_query: true)
            expect(page).to have_content(
              'The global settings require you to enable Two-Factor Authentication for your account'
            )
          end
        end
      end
    end

    context 'when user has two-factor authentication enabled' do
      let_it_be(:user) { create(:user, :two_factor_via_otp, :two_factor_via_webauthn) }

      it 'requires the current_password to delete the OTP authenticator', :js do
        visit profile_two_factor_auth_path

        find_button(_('Delete one-time password authenticator')).click
        modal_submit('wrong_password')

        expect(page).to have_selector('.gl-alert-title', text: invalid_current_pwd_msg, count: 1)

        find_button(_('Delete one-time password authenticator')).click
        modal_submit(user.password)

        expect(page).to have_content(_('One-time password authenticator has been deleted!'))
      end

      it 'requires the current_password to disable two-factor authentication', :js do
        visit profile_two_factor_auth_path

        click_button _('Disable 2FA')
        modal_submit('wrong_password')

        expect(page).to have_selector('.gl-alert-title', text: invalid_current_pwd_msg, count: 1)

        click_button _('Disable 2FA')
        modal_submit(user.password)

        expect(page).to have_content('Two-factor authentication has been disabled successfully!')
      end

      it 'requires the current_password to regenerate recovery codes', :js do
        visit profile_two_factor_auth_path

        click_button _('Regenerate recovery codes')
        modal_submit('wrong_password')

        expect(page).to have_selector('.gl-alert-title', text: invalid_current_pwd_msg, count: 1)

        click_button _('Regenerate recovery codes')
        modal_submit(user.password)

        expect(page).to have_content('Please copy, download, or print your recovery codes before proceeding.')
      end

      context 'when user authenticates with an external service' do
        let_it_be(:user) { create(:omniauth_user, :two_factor) }

        it 'does not require the current_password to delete the OTP authenticator', :js do
          visit profile_two_factor_auth_path

          find_button(_('Delete one-time password authenticator')).click
          modal_submit_without_password

          expect(page).to have_content(_('One-time password authenticator has been deleted!'))
        end

        it 'does not require the current_password to disable two-factor authentication', :js do
          visit profile_two_factor_auth_path

          click_button _('Disable 2FA')
          modal_submit_without_password

          expect(page).to have_content('Two-factor authentication has been disabled successfully!')
        end

        it 'does not require the current_password to regenerate recovery codes', :js do
          visit profile_two_factor_auth_path

          click_button _('Regenerate recovery codes')
          modal_submit_without_password

          expect(page).to have_content('Please copy, download, or print your recovery codes before proceeding.')
        end
      end
    end

    context 'when group requires 2FA', :js do
      let(:group_require_2fa) { create(:group, require_two_factor_authentication: true) }
      let(:group_name) { group_require_2fa.name }

      before do
        group_require_2fa.add_developer(user)

        sign_in(user)
      end

      context 'when user has no OTP enabled' do
        let(:user) { create(:user) }

        it 'does not allow user to access the group without setting up MFA' do
          visit profile_two_factor_auth_path

          expect_user_cannot_visit_group_path_without_enabling_2fa(group_name)
        end
      end

      context 'when user only has email-based otp' do
        let(:user) { create(:user, email_otp_required_after: 1.day.ago) }

        context 'when user only belongs to the group which enforces MFA' do
          it 'does not allow user to access the group without setting up a non-email-based OTP' do
            visit profile_two_factor_auth_path

            expect_user_cannot_visit_group_path_without_enabling_2fa(group_name)
          end
        end
      end

      context 'when user has both app-based and email-based 2FA' do
        let(:user) { create(:user, :two_factor_via_otp, email_otp_required_after: 1.day.ago) }

        it 'restricts access when app-based TOTP is removed' do
          # Can access group resources with both OTP methods enabled
          visit group_path(group_require_2fa)
          expect(page).to have_current_path(group_path(group_require_2fa))

          # Remove app-based TOTP
          visit profile_two_factor_auth_path
          find_button(_('Delete one-time password authenticator')).click
          modal_submit(user.password)

          expect_user_cannot_visit_group_path_without_enabling_2fa(group_name)
        end
      end
    end

    context 'for email OTP enrollment', :js do
      let(:email_otp_required_after) { nil }
      let(:user) { create(:user, email_otp_required_after: email_otp_required_after) }

      context 'when email_based_mfa feature flag is disabled' do
        before do
          stub_feature_flags(email_based_mfa: false)
        end

        it 'does not show the email OTP section' do
          visit profile_two_factor_auth_path

          expect(page).not_to have_content('Email one-time password (email OTP)')
        end
      end

      it 'shows the email OTP section' do
        visit profile_two_factor_auth_path

        within('#email-otp-settings') do
          expect(page).to have_content('Email one-time password (email OTP)')
          expect(page).to have_field('Enable email OTP', disabled: false)
          expect(page).to have_button('Save changes', disabled: false)
        end
      end

      it 'does not allow updating if incorrect password provided' do
        visit profile_two_factor_auth_path

        check 'Enable email OTP'

        email_otp_save_and_enter_password('incorrect-password')
        expect(page).to have_content(invalid_current_pwd_msg)

        expect(user.reload.email_otp_required_after).to be_nil
      end

      it 'allows updating when correct password provided', :freeze_time do
        visit profile_two_factor_auth_path

        check 'Enable email OTP'

        email_otp_save_and_enter_password(user.password)

        expect(page).to have_current_path(profile_two_factor_auth_path)
        expect(page).to have_content('Profile was successfully updated')
        expect(user.reload.email_otp_required_after).to eq(Time.current)
      end

      context 'when email_otp_required_after is nil' do
        it 'shows the checkbox as unchecked' do
          visit profile_two_factor_auth_path

          expect(page).to have_unchecked_field('Enable email OTP')
        end
      end

      context 'when email_otp_required_after is in the past' do
        let(:email_otp_required_after) { 1.day.ago }

        it 'shows the checkbox as checked without help text' do
          visit profile_two_factor_auth_path

          expect(page).to have_checked_field('Enable email OTP')
          expect(page).not_to have_content('You can skip email verification for now')
        end
      end

      context 'when email_otp_required_after is in the future' do
        let(:email_otp_required_after) { 30.days.from_now }

        it 'shows the checkbox as checked with future enforcement date' do
          visit profile_two_factor_auth_path

          expect(page).to have_field('Enable email OTP', checked: true, disabled: true)
          expect(page).to have_content('You can skip email verification for now')
          expect(page).to have_content(I18n.l(email_otp_required_after.to_date, format: :long))
          expect(page).to have_button('Save changes', disabled: true)
        end
      end

      context 'when user cannot modify enrollment' do
        let(:email_otp_required_after) { Time.current }

        before do
          stub_application_setting(require_minimum_email_based_otp_for_users_with_passwords: true)
        end

        it 'disables the checkbox and submit button with a tooltip' do
          visit profile_two_factor_auth_path

          expect(page).to have_field('Enable email OTP', checked: true, disabled: true)
          expect(page).to have_button('Save changes', disabled: true)
          expect(page).to have_content('You cannot modify your enrollment because')
        end
      end

      def email_otp_save_and_enter_password(password = nil)
        click_button 'Save changes'
        fill_in 'current_password', with: password
        click_button _('Update email OTP settings')
      end
    end

    def modal_submit(password)
      within_modal do
        fill_in 'current_password', with: password
        find_by_testid('2fa-action-primary').click
      end
    end

    def modal_submit_without_password
      within_modal do
        find_by_testid('2fa-action-primary').click
      end
    end

    def expect_user_cannot_visit_group_path_without_enabling_2fa(group_name)
      visit group_path(group_name)
      expect(page).to have_current_path(profile_two_factor_auth_path, ignore_query: true)
      expect(page).to have_content(
        "The group settings for #{group_name} require you to enable Two-Factor Authentication for your account"
      )
    end
  end
end
