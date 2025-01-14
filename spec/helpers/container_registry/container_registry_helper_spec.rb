# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::ContainerRegistryHelper, feature_category: :container_registry, type: :helper do
  include Devise::Test::ControllerHelpers

  let_it_be(:project) { build_stubbed(:project, :repository) }
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:admin) { build_stubbed(:admin) }
  let_it_be(:container_expiration_policy) { build_stubbed(:container_expiration_policy, project: project) }

  before_all do
    project.add_maintainer(user)
    project.add_maintainer(admin)
  end

  describe '#project_container_registry_template_data' do
    subject(:project_container_registry_template_data) do
      helper.project_container_registry_template_data(project, connection_error, invalid_path_error)
    end

    let(:connection_error) { nil }
    let(:invalid_path_error) { nil }

    it 'returns the correct template data' do
      allow(helper).to receive(:current_user).and_return(user)

      expect(project_container_registry_template_data).to include(
        endpoint: helper.project_container_registry_index_path(project),
        expiration_policy: container_expiration_policy.to_json,
        no_containers_image: match_asset_path('illustrations/status/status-nothing-md.svg'),
        containers_error_image: match_asset_path('illustrations/status/status-fail-md.svg'),
        repository_url: escape_once(project.container_registry_url),
        registry_host_url_with_port: escape_once(Gitlab.config.registry.host_port),
        project_path: project.full_path,
        gid_prefix: helper.container_repository_gid_prefix,
        is_admin: user.admin.to_s,
        show_cleanup_policy_link: helper.show_cleanup_policy_link(project).to_s,
        cleanup_policies_settings_path:
          helper.cleanup_image_tags_project_settings_packages_and_registries_path(project),
        show_container_registry_settings: helper.show_container_registry_settings(project).to_s,
        settings_path:
          helper.project_settings_packages_and_registries_path(project, anchor: 'container-registry-settings'),
        connection_error: (!!connection_error).to_s,
        invalid_path_error: (!!invalid_path_error).to_s,
        user_callouts_path: callouts_path,
        user_callout_id: Users::CalloutsHelper::UNFINISHED_TAG_CLEANUP_CALLOUT,
        is_metadata_database_enabled: ContainerRegistry::GitlabApiClient.supports_gitlab_api?.to_s,
        show_unfinished_tag_cleanup_callout: helper.show_unfinished_tag_cleanup_callout?.to_s
      )
    end

    context 'when there is a connection error' do
      let(:connection_error) { true }

      it 'sets connection_error to true' do
        allow(helper).to receive(:current_user).and_return(user)
        expect(project_container_registry_template_data[:connection_error]).to eq('true')
      end
    end

    context 'when there is an invalid path error' do
      let(:invalid_path_error) { true }

      it 'sets invalid_path_error to true' do
        allow(helper).to receive(:current_user).and_return(user)
        expect(project_container_registry_template_data[:invalid_path_error]).to eq('true')
      end
    end

    context 'when current user is admin' do
      before do
        allow(helper).to receive(:current_user).and_return(admin)
      end

      it 'sets is_admin to true' do
        expect(project_container_registry_template_data[:is_admin]).to eq('true')
      end
    end
  end

  describe '#container_repository_gid_prefix' do
    subject { helper.container_repository_gid_prefix }

    it { is_expected.to eq('gid://gitlab/ContainerRepository/') }
  end
end
