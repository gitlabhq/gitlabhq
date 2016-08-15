require 'spec_helper'

describe 'Profile > Password', feature: true do
  let(:user) { create(:user, password_automatically_set: true) }

  before do
    login_as(user)
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

      it 'does not contains the current password field after an error' do
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
