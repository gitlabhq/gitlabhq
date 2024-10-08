# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Applications', feature_category: :user_profile do
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

      within_testid 'breadcrumb-links' do
        expect(find('li:last-of-type')).to have_link(application.name)
      end
    end

    it 'deletes an application' do
      create(:oauth_application, owner: user)
      visit oauth_applications_path

      within_testid('oauth-applications') do
        within_testid('crud-count') do
          expect(page).to have_content('1')
        end
        click_button 'Destroy'
      end

      accept_gl_confirm(button_text: 'Destroy')

      expect(page).to have_content('The application was deleted successfully')
      within_testid('oauth-applications') do
        within_testid('crud-count') do
          expect(page).to have_content('0')
        end
      end
      within_testid('oauth-authorized-applications') do
        within_testid('crud-count') do
          expect(page).to have_content('0')
        end
      end
    end
  end

  describe 'Authorized applications', :js do
    let(:other_user) { create(:user) }
    let(:application) { create(:oauth_application, owner: user) }
    let(:created_at) { 2.days.ago }
    let(:token) { create(:oauth_access_token, application: application, resource_owner: user) }
    let(:anonymous_token) { create(:oauth_access_token, resource_owner: user) }

    context 'with multiple access token types and multiple owners' do
      let!(:token2) { create(:oauth_access_token, application: application, resource_owner: user) }
      let!(:other_user_token) { create(:oauth_access_token, application: application, resource_owner: other_user) }

      before do
        token.update_column(:created_at, created_at)
        token2.update_column(:created_at, created_at - 1.day)
        anonymous_token.update_columns(application_id: nil, created_at: 1.day.ago)
      end

      it 'displays the correct authorized applications' do
        visit oauth_applications_path

        within_testid('oauth-authorized-applications') do
          within_testid('crud-count') do
            expect(page).to have_content('2')
          end
        end

        within_testid('oauth-authorized-applications') do
          # Ensure the correct user's token details are displayed
          # when the application has more than one token
          page.within("tr#application_#{application.id}") do
            expect(page).to have_content(created_at)
          end

          expect(page).to have_content('Anonymous')
          expect(page).not_to have_content(other_user_token.created_at)
        end
      end
    end

    it 'deletes an authorized application' do
      token
      visit oauth_applications_path

      within_testid('oauth-authorized-applications') do
        page.within("tr#application_#{application.id}") do
          click_button 'Revoke'
        end
      end

      accept_gl_confirm(button_text: 'Revoke application')

      expect(page).to have_content('The application was revoked access.')
      within_testid('oauth-authorized-applications') do
        within_testid('crud-count') do
          expect(page).to have_content('0')
        end
      end
    end

    it 'deletes an anonymous authorized application' do
      anonymous_token
      visit oauth_applications_path

      within_testid('oauth-authorized-applications') do
        within_testid('crud-count') do
          expect(page).to have_content('1')
        end
        click_button 'Revoke'
      end

      accept_gl_confirm(button_text: 'Revoke application')

      expect(page).to have_content('The application was revoked access.')
      within_testid('oauth-authorized-applications') do
        within_testid('crud-count') do
          expect(page).to have_content('0')
        end
      end
    end
  end
end
