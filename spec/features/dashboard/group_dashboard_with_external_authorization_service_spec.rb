# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'The group dashboard', :js, feature_category: :subgroups do
  include ExternalAuthorizationServiceHelpers
  include Features::TopNavSpecHelpers

  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'The top navigation' do
    it 'has all the expected links' do
      visit dashboard_groups_path

      open_top_nav

      within_top_nav do
        expect(page).to have_button('Projects')
        expect(page).to have_button('Groups')
        expect(page).to have_link('Your work')
        expect(page).to have_link('Explore')
      end
    end

    it 'hides some links when an external authorization service is enabled' do
      enable_external_authorization_service_check
      visit dashboard_groups_path

      open_top_nav

      within_top_nav do
        expect(page).to have_button('Projects')
        expect(page).to have_button('Groups')
        expect(page).to have_link('Your work')
        expect(page).to have_link('Explore')
      end
    end
  end
end
