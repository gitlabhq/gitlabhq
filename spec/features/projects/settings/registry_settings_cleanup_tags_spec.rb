# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Settings > Packages & Registries > Container registry tag expiration policy' do
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
    it 'shows available section' do
      subject

      expect(find('.breadcrumbs')).to have_content('Clean up image tags')
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
