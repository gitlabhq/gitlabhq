# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Package and registry settings', feature_category: :package_registry do
  include WaitForRequests

  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:sub_group) { create(:group, parent: group) }

  before do
    group.add_owner(user)
    sub_group.add_owner(user)
    sign_in(user)
  end

  context 'when packages feature is disabled on the group' do
    before do
      stub_packages_setting(enabled: false)
    end

    it 'the menu item is not visible', :js do
      visit group_path(group)

      within_testid('super-sidebar') do
        click_button 'Settings'
        expect(page).not_to have_content 'Packages and registries'
      end
    end

    it 'renders 404 when navigating to page' do
      visit_settings_page

      expect(page).to have_content('Page not found')
    end
  end

  context 'when packages feature is enabled on the group' do
    it 'the menu item is visible', :js do
      visit group_path(group)

      within_testid('super-sidebar') do
        click_button 'Settings'
        expect(page).to have_content 'Packages and registries'
      end
    end

    it 'has a page title set' do
      visit_settings_page

      expect(page).to have_title _('Packages and registries settings')
    end

    it 'sidebar menu is open', :js do
      visit_settings_page

      within_testid('super-sidebar') do
        expect(page).to have_link _('Packages and registries')
      end
    end

    it 'passes axe automated accessibility testing', :js do
      visit_settings_page

      wait_for_requests

      expect(page).to be_axe_clean.within('[data-testid="packages-and-registries-group-settings"]') # rubocop:todo Capybara/TestidFinders -- Doesn't cover use case, see https://gitlab.com/gitlab-org/gitlab/-/issues/442224
                                  .skipping :'link-in-text-block'
    end

    it 'has a Duplicate packages section', :js do
      visit_settings_page

      expect(page).to have_content('Duplicate packages')
      expect(page).to have_content('Allow duplicates')
      expect(page).to have_content('Exceptions')
    end

    it 'automatically saves changes to the server', :js do
      visit_settings_page
      wait_for_requests

      within_testid 'maven-settings' do
        click_button class: 'gl-toggle'
      end

      expect(find('.gl-toast')).to have_content('Settings saved successfully.')
    end

    it 'shows an error on wrong regex', :js do
      visit_settings_page
      wait_for_requests

      within_testid 'maven-settings' do
        click_button class: 'gl-toggle'

        fill_in class: 'gl-form-input', with: ')'

        # simulate blur event
        send_keys(:tab)
      end

      expect(page).to have_content('is an invalid regexp')
    end

    context 'in a sub group' do
      it 'automatically saves changes to the server', :js do
        visit_sub_group_settings_page
        wait_for_requests

        within_testid 'maven-settings' do
          click_button class: 'gl-toggle'
        end

        expect(find('.gl-toast')).to have_content('Settings saved successfully.')
      end
    end
  end

  def visit_settings_page
    visit group_settings_packages_and_registries_path(group)
  end

  def visit_sub_group_settings_page
    visit group_settings_packages_and_registries_path(sub_group)
  end
end
