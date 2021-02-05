# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Packages & Registries settings' do
  include WaitForRequests

  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'when the feature flag is off' do
    before do
      stub_feature_flags(packages_and_registries_group_settings: false)
    end

    it 'the menu item is not visible' do
      visit group_path(group)

      settings_menu = find_settings_menu

      expect(settings_menu).not_to have_content 'Packages & Registries'
    end
  end

  context 'when the feature flag is on' do
    it 'the menu item is visible' do
      visit group_path(group)

      settings_menu = find_settings_menu
      expect(settings_menu).to have_content 'Packages & Registries'
    end

    it 'has a page title set' do
      visit_settings_page

      expect(page).to have_title _('Packages & Registries')
    end

    it 'sidebar menu is open' do
      visit_settings_page

      sidebar = find('.nav-sidebar')
      expect(sidebar).to have_link _('Packages & Registries')
    end

    it 'has a Package Registry section', :js do
      visit_settings_page

      expect(page).to have_content('Package Registry')
      expect(page).to have_button('Collapse')
    end

    it 'automatically saves changes to the server', :js do
      visit_settings_page

      expect(page).to have_content('Allow duplicates')

      find('.gl-toggle').click

      expect(page).to have_content('Do not allow duplicates')

      visit_settings_page

      expect(page).to have_content('Do not allow duplicates')
    end

    it 'shows an error on wrong regex', :js do
      visit_settings_page

      expect(page).to have_content('Allow duplicates')

      find('.gl-toggle').click

      expect(page).to have_content('Do not allow duplicates')

      fill_in 'Exceptions', with: ')'

      # simulate blur event
      find('body').click

      expect(page).to have_content('is an invalid regexp')
    end
  end

  def find_settings_menu
    find('ul[data-testid="group-settings-menu"]')
  end

  def visit_settings_page
    visit group_settings_packages_and_registries_path(group)
  end
end
