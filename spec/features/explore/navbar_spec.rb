# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '"Explore" navbar', :js, :with_current_organization, feature_category: :navigation do
  include_context '"Explore" navbar structure'

  let_it_be(:user) { create(:user, organizations: [current_organization]) }

  it_behaves_like 'verified navigation bar' do
    before do
      sign_in(user)
      visit explore_projects_path
    end
  end

  context 'when explore_analytics_dashboards feature is disabled' do
    before do
      stub_feature_flags(explore_analytics_dashboards: false)

      sign_in(user)
      visit explore_projects_path
    end

    it 'renders the correct nav items' do
      within_testid('nav-container') do
        items = all('[data-testid="nav-item-link-label"]').collect(&:text)

        expect(items).not_to include("Analytics dashboards")
      end
    end
  end
end
