# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'The group page', :js, feature_category: :groups_and_projects do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group, :crm_disabled) }

  before do
    sign_in user
    group.add_owner(user)
  end

  def expect_all_sidebar_links
    within('#super-sidebar .contextual-nav') do
      click_button 'Manage'
      click_button 'Plan'
      expect(page).to have_link('Activity')
      expect(page).to have_link('Issues')
      expect(page).to have_link('Merge requests')
      expect(page).to have_link('Members')
    end
  end

  describe 'The sidebar' do
    it 'has all the expected links' do
      visit group_path(group)

      expect_all_sidebar_links
    end

    it 'shows all project features when policy control is enabled' do
      stub_application_setting(external_authorization_service_enabled: true)

      visit group_path(group)

      expect_all_sidebar_links
    end

    it 'hides some links when an external authorization service configured with an url' do
      enable_external_authorization_service_check
      visit group_path(group)

      within('#super-sidebar .contextual-nav') do
        expect(page).not_to have_button('Plan')

        click_button 'Manage'

        expect(page).not_to have_link('Activity')
        expect(page).not_to have_link('Contribution')

        expect(page).not_to have_link('Issues')
        expect(page).not_to have_link('Merge requests')
        expect(page).to have_link('Members')
      end
    end
  end
end
