# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User Settings > Password', feature_category: :user_profile do
  let(:user) { create(:user) }

  def fill_passwords(password, confirmation)
    fill_in 'New password',          with: password
    fill_in 'Password confirmation', with: confirmation

    click_button 'Save password'
  end

  context 'when password authentication enabled' do
    let(:new_password) { User.random_password }
    let(:user) { create(:user, password_automatically_set: true) }

    before do
      sign_in(user)
      visit edit_user_settings_password_path
    end

    context 'when User with password automatically set' do
      describe 'User puts different passwords in the field and in the confirmation' do
        it 'shows an error message' do
          fill_passwords(new_password, "#{new_password}2")

          page.within('.gl-alert-danger') do
            expect(page).to have_content("Password confirmation doesn't match Password")
          end
        end

        it 'does not contain the current password field after an error' do
          fill_passwords(new_password, "#{new_password}2")

          expect(page).to have_no_field('user[current_password]')
        end
      end

      describe 'User puts the same passwords in the field and in the confirmation' do
        it 'shows a success message' do
          fill_passwords(new_password, new_password)

          within_testid('alert-info') do
            expect(page).to have_content('Password was successfully updated. Please sign in again.')
          end
        end
      end
    end
  end

  context 'when password authentication unavailable' do
    context 'with Regular user' do
      before do
        gitlab_sign_in(user)
      end

      let(:user) { create(:user) }

      it 'renders 404 when password authentication is disabled for the web interface and Git' do
        stub_application_setting(password_authentication_enabled_for_web: false)
        stub_application_setting(password_authentication_enabled_for_git: false)

        visit edit_user_settings_password_path

        expect(page).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with LDAP user' do
      include LdapHelpers

      let(:ldap_settings) { { enabled: true } }
      let(:user) { create(:omniauth_user, provider: 'ldapmain') }
      let(:provider) { 'ldapmain' }
      let(:provider_label) { 'Main LDAP' }

      before do
        stub_ldap_setting(ldap_settings)
        stub_ldap_access(user, provider, provider_label)
        sign_in_using_ldap!(user, provider_label, provider)
      end

      after(:all) do
        Rails.application.reload_routes!
      end

      it 'renders 404', :js do
        visit edit_user_settings_password_path

        expect(page).to have_title('Not Found')
        expect(page).to have_content('Page not found')
      end
    end
  end

  context 'when changing password' do
    let(:new_password) { User.random_password }

    before do
      sign_in(user)
      visit(edit_user_settings_password_path)
    end

    shared_examples 'user enters an incorrect current password' do
      subject do
        page.within '.update-password' do
          fill_in 'user_password', with: user_current_password
          fill_passwords(new_password, new_password)
        end
      end

      it 'handles the invalid password attempt, and prompts the user to try again', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:info)
          .with(message: 'Invalid current password when attempting to update user password', username: user.username,
            ip: user.current_sign_in_ip)

        subject

        user.reload

        expect(user.failed_attempts).to eq(1)
        expect(user.valid_password?(new_password)).to eq(false)
        expect(page).to have_current_path(edit_user_settings_password_path, ignore_query: true)

        page.within '.flash-container' do
          expect(page).to have_content('You must provide a valid current password')
        end
      end

      it 'locks the user account when user passes the maximum attempts threshold', :aggregate_failures do
        user.update!(failed_attempts: User.maximum_attempts.pred)

        subject

        expect(page).to have_current_path(new_user_session_path, ignore_query: true)

        page.within '.flash-container' do
          expect(page).to have_content('Your account is locked.')
        end
      end
    end

    context 'when current password is blank' do
      let(:user_current_password) { nil }

      it_behaves_like 'user enters an incorrect current password'
    end

    context 'when current password is incorrect' do
      let(:user_current_password) { 'invalid' }

      it_behaves_like 'user enters an incorrect current password'
    end

    context 'when the password is too weak' do
      let(:new_password) { 'password' }

      subject do
        page.within '.update-password' do
          fill_in "user_password", with: user.password
          fill_passwords(new_password, new_password)
        end
      end

      it 'tracks the error and does not change the password', :aggregate_failures do
        expect { subject }.not_to change { user.reload.valid_password?(new_password) }
        expect(user.failed_attempts).to eq(0)

        page.within '.gl-alert-danger' do
          expect(page).to have_content('must not contain commonly used combinations of words and letters')
        end

        expect_snowplow_event(
          category: 'Gitlab::Tracking::Helpers::WeakPasswordErrorEvent',
          action: 'track_weak_password_error',
          controller: 'UserSettings::PasswordsController',
          method: 'update'
        )
      end
    end

    context 'when the password reset is successful' do
      subject do
        page.within '.update-password' do
          fill_in "user_password", with: user.password
          fill_passwords(new_password, new_password)
        end
      end

      it 'changes the password, logs the user out and prompts them to sign in again', :aggregate_failures do
        expect { subject }.to change { user.reload.valid_password?(new_password) }.to(true)
        expect(page).to have_current_path new_user_session_path, ignore_query: true

        page.within '.flash-container' do
          expect(page).to have_content('Password was successfully updated. Please sign in again.')
        end
      end
    end
  end

  context 'when password is expired' do
    let(:new_password) { User.random_password }

    before do
      sign_in(user)

      user.update!(password_expires_at: 1.hour.ago)
      user.identities.delete
    end

    it 'needs change user password' do
      visit edit_user_settings_password_path

      expect(page).to have_current_path new_user_settings_password_path, ignore_query: true

      fill_in :user_password,      with: user.password
      fill_in :user_new_password,  with: new_password
      fill_in :user_password_confirmation, with: new_password
      click_button 'Update password'

      expect(page).to have_current_path new_user_session_path, ignore_query: true
    end

    it 'tracks weak password error' do
      visit edit_user_settings_password_path

      expect(page).to have_current_path new_user_settings_password_path, ignore_query: true

      fill_in :user_password,      with: user.password
      fill_in :user_new_password,  with: "password"
      fill_in :user_password_confirmation, with: "password"
      click_button 'Update password'
      expect_snowplow_event(
        category: 'Gitlab::Tracking::Helpers::WeakPasswordErrorEvent',
        action: 'track_weak_password_error',
        controller: 'UserSettings::PasswordsController',
        method: 'create'
      )
    end

    context 'when global require_two_factor_authentication is enabled' do
      it 'needs change user password' do
        stub_application_setting(require_two_factor_authentication: true)

        visit user_settings_profile_path

        expect(page).to have_current_path new_user_settings_password_path, ignore_query: true
      end
    end
  end
end
