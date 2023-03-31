# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Settings > Packages and registries > Container registry tag expiration policy',
feature_category: :projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, namespace: user.namespace) }

  let(:container_registry_enabled) { true }
  let(:container_registry_enabled_on_project) { ProjectFeature::ENABLED }

  subject { visit project_settings_packages_and_registries_path(project) }

  before do
    project.project_feature.update!(container_registry_access_level: container_registry_enabled_on_project)
    project.container_expiration_policy.update!(enabled: true)

    sign_in(user)
    stub_container_registry_config(enabled: container_registry_enabled)
  end

  context 'as owner', :js do
    it 'passes axe automated accessibility testing' do
      subject

      wait_for_requests

      expect(page).to be_axe_clean.within('[data-testid="packages-and-registries-project-settings"]')
                                  .skipping :'link-in-text-block'
    end

    it 'shows active tab on sidebar' do
      subject

      expect(find('.sidebar-top-level-items > li.active')).to have_content('Settings')
      expect(find('.sidebar-sub-level-items > li.active:not(.fly-out-top-item)'))
        .to have_content('Packages and registries')
    end

    it 'shows available section' do
      subject

      settings_block = find('[data-testid="container-expiration-policy-project-settings"]')
      expect(settings_block).to have_text 'Cleanup policies'
    end

    it 'contains link to cleanup policies page' do
      subject

      expect(page).to have_link('Edit cleanup rules', href: cleanup_image_tags_project_settings_packages_and_registries_path(project))
    end
  end

  context 'with a project without expiration policy', :js do
    before do
      project.container_expiration_policy.destroy!
    end

    context 'with container_expiration_policies_enable_historic_entries enabled' do
      before do
        stub_application_setting(container_expiration_policies_enable_historic_entries: true)
      end

      it 'displays the related section' do
        subject

        within '[data-testid="container-expiration-policy-project-settings"]' do
          expect(page).to have_link('Set cleanup rules', href: cleanup_image_tags_project_settings_packages_and_registries_path(project))
        end
      end
    end

    context 'with container_expiration_policies_enable_historic_entries disabled' do
      before do
        stub_application_setting(container_expiration_policies_enable_historic_entries: false)
      end

      it 'does not display the related section' do
        subject

        within '[data-testid="container-expiration-policy-project-settings"]' do
          expect(find('.gl-alert-title')).to have_content('Cleanup policy for tags is disabled')
        end
      end
    end
  end

  context 'when registry is disabled' do
    let(:container_registry_enabled) { false }

    it 'does not exists' do
      subject

      expect(page).not_to have_selector('[data-testid="container-expiration-policy-project-settings"]')
    end
  end

  context 'when container registry is disabled on project' do
    let(:container_registry_enabled_on_project) { ProjectFeature::DISABLED }

    it 'does not exists' do
      subject

      expect(page).not_to have_selector('[data-testid="container-expiration-policy-project-settings"]')
    end
  end
end
