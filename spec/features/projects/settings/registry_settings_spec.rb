# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Settings > Packages and registries', feature_category: :container_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, namespace: user.namespace) }

  let(:container_registry_enabled) { true }
  let(:container_registry_enabled_on_project) { ProjectFeature::ENABLED }

  let(:help_page_href) { help_page_path('administration/packages/container_registry_metadata_database.md') }

  before do
    project.project_feature.update!(container_registry_access_level: container_registry_enabled_on_project)
    project.container_expiration_policy.update!(enabled: true)

    sign_in(user)
    stub_container_registry_config(enabled: container_registry_enabled)
    allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(true)
  end

  describe 'layout', :js do
    it 'renders sections' do
      visit_page

      expect(page).to have_selector 'h1.gl-sr-only', text: 'Packages and registries settings'
      expect(page).to have_selector 'h2', text: 'Package registry'
      expect(page).to have_selector 'h2', text: 'Container registry'
    end

    it 'shows active tab on sidebar' do
      visit_page

      within_testid('super-sidebar') do
        expect(page).to have_selector('button[aria-expanded="true"]', text: 'Settings')
        expect(page).to have_selector('[aria-current="page"]', text: 'Packages and registries')
      end
    end

    it 'passes axe automated accessibility testing' do
      visit_page

      click_button 'Expand Package registry'

      click_button 'Expand Container registry'

      wait_for_requests

      expect(page).to be_axe_clean.within('[data-testid="packages-and-registries-project-settings"]') # rubocop:todo Capybara/TestidFinders -- Doesn't cover use case, see https://gitlab.com/gitlab-org/gitlab/-/issues/442224
                                  .skipping :'link-in-text-block'
    end
  end

  shared_examples 'tags cleanup policy settings' do
    it 'shows available section' do
      visit_method

      settings_block = find_by_testid('container-expiration-policy-project-settings')
      expect(settings_block).to have_text 'Container registry cleanup policies'
    end

    it 'contains link to cleanup policies page' do
      visit_method

      expect(page).to have_link('Edit cleanup rules', href: cleanup_image_tags_project_settings_packages_and_registries_path(project))
    end

    it 'has link to next generation container registry docs' do
      allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(false)

      visit_method

      expect(page).to have_link('next-generation container registry', href: help_page_href)
    end

    context 'with a project without expiration policy' do
      before do
        project.container_expiration_policy.destroy!
      end

      context 'with container_expiration_policies_enable_historic_entries enabled' do
        before do
          stub_application_setting(container_expiration_policies_enable_historic_entries: true)
        end

        it 'displays the related section' do
          visit_method

          within_testid 'container-expiration-policy-project-settings' do
            expect(page).to have_link('Set cleanup rules', href: cleanup_image_tags_project_settings_packages_and_registries_path(project))
          end
        end
      end

      context 'with container_expiration_policies_enable_historic_entries disabled' do
        before do
          stub_application_setting(container_expiration_policies_enable_historic_entries: false)
        end

        it 'does not display the related section' do
          visit_method

          within_testid 'container-expiration-policy-project-settings' do
            expect(find('.gl-alert-title')).to have_content('Cleanup policy for tags is disabled')
          end
        end
      end
    end
  end

  describe 'container registry tags cleanup policy', :js do
    it_behaves_like 'tags cleanup policy settings' do
      let(:visit_method) { visit_and_expand_section }
    end
  end

  context 'with feature flag disabled', :js do
    before do
      stub_feature_flags(reorganize_project_level_registry_settings: false)
    end

    it 'passes axe automated accessibility testing' do
      visit_page

      wait_for_requests

      expect(page).to have_selector 'h1.gl-sr-only', text: 'Packages and registries settings'
      expect(page).to be_axe_clean.within('[data-testid="packages-and-registries-project-settings"]') # rubocop:todo Capybara/TestidFinders -- Doesn't cover use case, see https://gitlab.com/gitlab-org/gitlab/-/issues/442224
    end

    it_behaves_like 'tags cleanup policy settings' do
      let(:visit_method) { visit_page }
    end
  end

  context 'when registry is disabled' do
    let(:container_registry_enabled) { false }

    it 'does not exists' do
      visit_page

      expect(page).not_to have_selector('[data-testid="container-expiration-policy-project-settings"]')
    end
  end

  context 'when container registry is disabled on project' do
    let(:container_registry_enabled_on_project) { ProjectFeature::DISABLED }

    it 'does not exists' do
      visit_page

      expect(page).not_to have_selector('[data-testid="container-expiration-policy-project-settings"]')
    end
  end

  private

  def visit_page
    visit project_settings_packages_and_registries_path(project)
  end

  def visit_and_expand_section
    visit_page

    click_button 'Expand Container registry'
  end
end
