# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'top nav responsive', :js do
  include MobileHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:responsive_menu_text) { 'Placeholder for responsive top nav' }

  before do
    stub_feature_flags(combined_menu: true)

    sign_in(user)
    visit explore_projects_path

    resize_screen_xs
  end

  context 'before opened' do
    it 'has page content and hides responsive menu', :aggregate_failures do
      expect(page).to have_css('.page-title', text: 'Projects')
      expect(page).to have_no_text(responsive_menu_text)
    end
  end

  context 'when opened' do
    before do
      click_button('Menu')
    end

    it 'hides everything and shows responsive menu', :aggregate_failures do
      expect(page).to have_no_css('.page-title', text: 'Projects')
      expect(page).to have_link('Dashboard', id: 'logo')
      expect(page).to have_text(responsive_menu_text)
    end
  end
end
