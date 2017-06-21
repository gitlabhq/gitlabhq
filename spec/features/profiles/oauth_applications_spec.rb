require 'spec_helper'

describe 'Profile > Applications', feature: true do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'User manages applications', js: true do
    it 'deletes an application' do
      create(:oauth_application, owner: user)
      visit oauth_applications_path

      page.within('.oauth-applications') do
        expect(page).to have_content('Your applications (1)')
        click_button 'Destroy'
      end

      expect(page).to have_content('The application was deleted successfully')
      expect(page).to have_content('Your applications (0)')
      expect(page).to have_content('Authorized applications (0)')
    end

    it 'deletes an authorized application' do
      create(:oauth_access_token, resource_owner: user)
      visit oauth_applications_path

      page.within('.oauth-authorized-applications') do
        expect(page).to have_content('Authorized applications (1)')
        click_button 'Revoke'
      end

      expect(page).to have_content('The application was revoked access.')
      expect(page).to have_content('Your applications (0)')
      expect(page).to have_content('Authorized applications (0)')
    end
  end
end
