# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'top nav responsive', :js do
  include MobileHelpers

  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
    visit explore_projects_path

    resize_screen_xs
  end

  context 'before opened' do
    it 'has page content and hides responsive menu', :aggregate_failures do
      expect(page).to have_css('.page-title', text: 'Projects')
      expect(page).to have_link('Dashboard', id: 'logo')

      expect(page).to have_no_css('.top-nav-responsive')
    end
  end

  context 'when opened' do
    before do
      click_button('Menu')
    end

    it 'hides everything and shows responsive menu', :aggregate_failures do
      expect(page).to have_no_css('.page-title', text: 'Projects')
      expect(page).to have_no_link('Dashboard', id: 'logo')

      within '.top-nav-responsive' do
        expect(page).to have_link(nil, href: search_path)
        expect(page).to have_button('Projects')
        expect(page).to have_button('Groups')
        expect(page).to have_link('Snippets', href: dashboard_snippets_path)
      end
    end

    it 'has new dropdown', :aggregate_failures do
      click_button('New...')

      expect(page).to have_link('New project', href: new_project_path)
      expect(page).to have_link('New group', href: new_group_path)
      expect(page).to have_link('New snippet', href: new_snippet_path)
    end
  end
end
