require 'spec_helper'

describe 'Profile > Password' do
  let(:user) { create(:user) }

  def fill_passwords(password, confirmation)
    fill_in 'New password',          with: password
    fill_in 'Password confirmation', with: confirmation

    click_button 'Save password'
  end

  context 'Password authentication enabled' do
    let(:user) { create(:user, password_automatically_set: true) }

    before do
      sign_in(user)
      visit edit_profile_password_path
    end

    context 'User with password automatically set' do
      describe 'User puts different passwords in the field and in the confirmation' do
        it 'shows an error message' do
          fill_passwords('mypassword', 'mypassword2')

          page.within('.alert-danger') do
            expect(page).to have_content("Password confirmation doesn't match Password")
          end
        end

        it 'does not contain the current password field after an error' do
          fill_passwords('mypassword', 'mypassword2')

          expect(page).to have_no_field('user[current_password]')
        end
      end

      describe 'User puts the same passwords in the field and in the confirmation' do
        it 'shows a success message' do
          fill_passwords('mypassword', 'mypassword')

          page.within('.flash-notice') do
            expect(page).to have_content('Password was successfully updated. Please login with it')
          end
        end
      end
    end
  end

  context 'Password authentication unavailable' do
    before do
      gitlab_sign_in(user)
    end

    context 'Regular user' do
      let(:user) { create(:user) }

      it 'renders 404 when password authentication is disabled for the web interface and Git' do
        stub_application_setting(password_authentication_enabled_for_web: false)
        stub_application_setting(password_authentication_enabled_for_git: false)

        visit edit_profile_password_path

        expect(page).to have_gitlab_http_status(404)
      end
    end

    context 'LDAP user' do
      let(:user) { create(:omniauth_user, provider: 'ldapmain') }

      it 'renders 404' do
        visit edit_profile_password_path

        expect(page).to have_gitlab_http_status(404)
      end
    end
  end

  context 'Change passowrd' do
    before do
      sign_in(user)
      visit(edit_profile_password_path)
    end

    it 'does not change user passowrd without old one' do
      page.within '.update-password' do
        fill_passwords('22233344', '22233344')
      end

      page.within '.flash-container' do
        expect(page).to have_content 'You must provide a valid current password'
      end
    end

    it 'does not change password with invalid old password' do
      page.within '.update-password' do
        fill_in 'user_current_password', with: 'invalid'
        fill_passwords('password', 'confirmation')
      end

      page.within '.flash-container' do
        expect(page).to have_content 'You must provide a valid current password'
      end
    end

    it 'changes user password' do
      page.within '.update-password' do
        fill_in "user_current_password", with: user.password
        fill_passwords('22233344', '22233344')
      end

      expect(current_path).to eq new_user_session_path
    end
  end

  context 'when password is expired' do
    before do
      sign_in(user)

      user.update_attributes(password_expires_at: 1.hour.ago)
      user.identities.delete
      expect(user.ldap_user?).to eq false
    end

    it 'needs change user password' do
      visit edit_profile_password_path

      expect(current_path).to eq new_profile_password_path

      fill_in :user_current_password,      with: user.password
      fill_in :user_password,              with: '12345678'
      fill_in :user_password_confirmation, with: '12345678'
      click_button 'Set new password'

      expect(current_path).to eq new_user_session_path
    end

    context 'when global require_two_factor_authentication is enabled' do
      it 'needs change user password' do
        stub_application_setting(require_two_factor_authentication: true)

        visit profile_path

        expect(current_path).to eq new_profile_password_path
      end
    end
  end
end
