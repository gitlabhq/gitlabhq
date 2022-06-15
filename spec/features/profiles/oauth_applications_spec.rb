# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Applications' do
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }
  let(:application) { create(:oauth_application, owner: user) }

  before do
    sign_in(user)
  end

  describe 'User manages applications', :js do
    it 'views an application' do
      visit oauth_application_path(application)

      expect(page).to have_content("Application: #{application.name}")
      expect(find('[data-testid="breadcrumb-current-link"]')).to have_link(application.name)
    end

    it 'deletes an application' do
      create(:oauth_application, owner: user)
      visit oauth_applications_path

      page.within('.oauth-applications') do
        expect(page).to have_content('Your applications (1)')
        click_button 'Destroy'
      end

      accept_gl_confirm(button_text: 'Destroy')

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

      accept_gl_confirm(button_text: 'Revoke application')

      expect(page).to have_content('The application was revoked access.')
      expect(page).to have_content('Your applications (0)')
      expect(page).to have_content('Authorized applications (0)')
    end
  end
end
