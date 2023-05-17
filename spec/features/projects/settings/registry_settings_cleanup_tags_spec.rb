# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Settings > Packages and registries > Container registry tag expiration policy',
feature_category: :projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, namespace: user.namespace) }

  let(:container_registry_enabled) { true }
  let(:container_registry_enabled_on_project) { ProjectFeature::ENABLED }

  subject { visit cleanup_image_tags_project_settings_packages_and_registries_path(project) }

  before do
    project.project_feature.update!(container_registry_access_level: container_registry_enabled_on_project)
    project.container_expiration_policy.update!(enabled: true)

    sign_in(user)
    stub_container_registry_config(enabled: container_registry_enabled)
  end

  context 'as owner', :js do
    it 'shows active tab on sidebar' do
      subject

      expect(find('.sidebar-top-level-items > li.active')).to have_content('Settings')
      expect(find('.sidebar-sub-level-items > li.active:not(.fly-out-top-item)'))
        .to have_content('Packages and registries')
    end

    it 'shows available section' do
      subject

      expect(find('.breadcrumbs')).to have_content('Cleanup policies')

      section = find('[data-testid="container-expiration-policy-project-settings"]')
      expect(section).to have_text 'Cleanup policies'
    end

    it 'passes axe automated accessibility testing' do
      subject

      wait_for_requests

      expect(page).to be_axe_clean.within('[data-testid="container-expiration-policy-project-settings"]')
                                  .skipping :'link-in-text-block'
    end

    it 'saves cleanup policy submit the form' do
      subject

      within '[data-testid="container-expiration-policy-project-settings"]' do
        select('Every day', from: 'Run cleanup')
        select('50 tags per image name', from: 'Keep the most recent:')
        fill_in('Keep tags matching:', with: 'stable')
        select('7 days', from: 'Remove tags older than:')
        fill_in('Remove tags matching:', with: '.*-production')

        submit_button = find('[data-testid="save-button"')
        expect(submit_button).not_to be_disabled
        submit_button.click
      end

      expect(page).to have_current_path(project_settings_packages_and_registries_path(project))
      expect(find('.gl-alert-body')).to have_content('Cleanup policy successfully saved.')
    end

    it 'does not save cleanup policy submit form with invalid regex' do
      subject

      within '[data-testid="container-expiration-policy-project-settings"]' do
        fill_in('Remove tags matching:', with: '*-production')

        submit_button = find('[data-testid="save-button"')
        expect(submit_button).not_to be_disabled
        submit_button.click
      end

      expect(find('.gl-toast')).to have_content('Something went wrong while updating the cleanup policy.')
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
          expect(find('[data-testid="enable-toggle"]'))
            .to have_content('Disabled - Tags will not be automatically deleted.')
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

      expect(page).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when container registry is disabled on project' do
    let(:container_registry_enabled_on_project) { ProjectFeature::DISABLED }

    it 'does not exists' do
      subject

      expect(page).to have_gitlab_http_status(:not_found)
    end
  end
end
