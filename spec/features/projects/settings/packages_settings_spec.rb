# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > Packages', :js do
  let_it_be(:project) { create(:project) }

  let(:user) { project.first_owner }

  before do
    sign_in(user)

    stub_config(packages: { enabled: packages_enabled })
    stub_feature_flags(package_registry_access_level: package_registry_access_level)

    visit edit_project_path(project)
  end

  context 'Packages enabled in config' do
    let(:packages_enabled) { true }

    context 'with feature flag disabled' do
      let(:package_registry_access_level) { false }

      it 'displays the packages toggle button' do
        expect(page).to have_selector('[data-testid="toggle-label"]', text: 'Packages')
        expect(page).to have_selector('input[name="project[packages_enabled]"] + button', visible: true)
      end
    end

    context 'with feature flag enabled' do
      let(:package_registry_access_level) { true }

      it 'displays the packages access level setting' do
        expect(page).to have_selector('[data-testid="package-registry-access-level"] > label', text: 'Package registry')
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
    let(:package_registry_access_level) { false }

    it 'does not show up in UI' do
      expect(page).not_to have_selector('[data-testid="toggle-label"]', text: 'Packages')
    end
  end
end
