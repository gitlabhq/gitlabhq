require 'spec_helper'

feature 'The group page' do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    sign_in user
    group.add_owner(user)
  end

  def expect_all_sidebar_links
    within('.nav-sidebar') do
      expect(page).to have_link('Overview')
      expect(page).to have_link('Details')
      expect(page).to have_link('Activity')
      expect(page).to have_link('Contribution Analytics')
      expect(page).to have_link('Issues')
      expect(page).to have_link('Merge Requests')
      expect(page).to have_link('Members')
    end
  end

  describe 'The sidebar' do
    it 'has all the expected links' do
      visit group_path(group)

      expect_all_sidebar_links
    end

    it 'shows all project features when policy control is enabled' do
      stub_ee_application_setting(external_authorization_service_enabled: true)

      visit group_path(group)

      expect_all_sidebar_links
    end

    it 'hides some links when an external authorization service configured with an url' do
      enable_external_authorization_service_check
      visit group_path(group)

      within('.nav-sidebar') do
        expect(page).to have_link('Overview')
        expect(page).to have_link('Details')
        expect(page).not_to have_link('Activity')
        expect(page).not_to have_link('Contribution Analytics')

        expect(page).not_to have_link('Issues')
        expect(page).not_to have_link('Merge Requests')
        expect(page).to have_link('Members')
      end
    end

    context 'when epics are available' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'shows the link to epics' do
        visit group_path(group)

        within('.nav-sidebar') do
          expect(page).to have_link('Epics')
        end
      end

      it 'hides the epics link when an external authorization service is enabled' do
        enable_external_authorization_service_check
        visit group_path(group)

        within('.nav-sidebar') do
          expect(page).not_to have_link('Epics')
        end
      end
    end
  end
end
