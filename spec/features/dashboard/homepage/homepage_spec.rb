# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard - Home', :js, feature_category: :notifications do
  let_it_be(:user) { create(:user) }

  before do
    stub_feature_flags(personal_homepage: true)
    sign_in user
  end

  describe 'visiting the /dashboard/home route' do
    it 'shows the personal homepage' do
      visit home_dashboard_path

      expect(page).to have_testid('homepage-greeting-header')
    end
  end

  describe 'visiting the root route' do
    context 'when using the default homepage (with flipped mapping)' do
      it 'shows the personal homepage' do
        visit root_path

        expect(page).to have_testid('homepage-greeting-header')
      end
    end

    context 'when explicitly setting dashboard to homepage (with flipped mapping)' do
      let_it_be(:user) { create(:user, dashboard: :homepage) }

      it 'shows the personal homepage' do
        visit root_path

        expect(page).to have_testid('homepage-greeting-header')
      end
    end
  end
end
