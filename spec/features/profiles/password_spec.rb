require 'spec_helper'

describe 'Profile > Password', feature: true do
  context 'Password authentication enabled' do
    let(:user) { create(:user, password_automatically_set: true) }

    before do
      sign_in(user)
      visit edit_profile_password_path
    end

    def fill_passwords(password, confirmation)
      fill_in 'New password',          with: password
      fill_in 'Password confirmation', with: confirmation

      click_button 'Save password'
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

      it 'renders 404 when sign-in is disabled' do
        stub_application_setting(password_authentication_enabled: false)

        visit edit_profile_password_path

        expect(page).to have_http_status(404)
      end
    end

    context 'LDAP user' do
      let(:user) { create(:omniauth_user, provider: 'ldapmain') }

      it 'renders 404' do
        visit edit_profile_password_path

        expect(page).to have_http_status(404)
      end
    end
  end
end
