# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > Packages', :js, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }

  let(:user) { project.first_owner }

  before do
    sign_in(user)

    stub_config(packages: { enabled: packages_enabled })

    visit edit_project_path(project)
  end

  context 'Packages enabled in config' do
    let(:packages_enabled) { true }

    it 'displays the packages access level setting' do
      within_testid('package-registry-access-level') do
        expect(page).to have_content('Package registry')
        expect(page).to have_selector('input[name="package_registry_enabled"]', visible: false)
        expect(page).to have_selector('input[name="package_registry_enabled"] + button', visible: true)
        expect(page).to have_selector('input[name="package_registry_api_for_everyone_enabled"]', visible: false)
        expect(page).to have_selector('input[name="package_registry_api_for_everyone_enabled"] + button', visible: true)
        expect(page).to have_selector(
          'input[name="project[project_feature_attributes][package_registry_access_level]"]',
          visible: false
        )
      end
    end
  end

  context 'Packages disabled in config' do
    let(:packages_enabled) { false }

    it 'does not show up in UI' do
      expect(page).not_to have_selector('[data-testid="toggle-label"]', text: 'Package registry')
    end
  end
end
