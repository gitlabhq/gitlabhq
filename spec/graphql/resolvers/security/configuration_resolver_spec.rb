# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Security::ConfigurationResolver, feature_category: :security_asset_inventories do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  let(:project_gid) { project.to_global_id }

  subject(:resolve_configuration) do
    resolve(
      described_class,
      args: { project_id: project_gid },
      ctx: { current_user: current_user },
      field_opts: { calls_gitaly: true }
    )
  end

  describe '#resolve' do
    context 'when user has permission' do
      before_all do
        project.add_developer(current_user)
      end

      it 'returns a hash with the correct keys' do
        result = resolve_configuration

        expect(result).to be_a(Hash)
        expect(result.keys).to include(
          :auto_devops_enabled,
          :auto_devops_help_page_path,
          :auto_devops_path,
          :can_enable_auto_devops,
          :features,
          :help_page_path,
          :latest_pipeline_path,
          :gitlab_ci_present,
          :gitlab_ci_history_path,
          :security_training_enabled,
          :container_scanning_for_registry_enabled,
          :secret_push_protection_available,
          :secret_push_protection_enabled,
          :secret_push_protection_licensed,
          :validity_checks_available,
          :validity_checks_enabled,
          :user_is_project_admin,
          :can_enable_spp,
          :is_gitlab_com,
          :secret_detection_configuration_path,
          :license_configuration_source,
          :vulnerability_training_docs_path,
          :upgrade_path,
          :group_full_path,
          :can_read_attributes,
          :can_manage_attributes,
          :group_manage_attributes_path
        )
      end

      it 'returns features as an array' do
        result = resolve_configuration

        expect(result[:features]).to be_an(Array)
      end
    end

    context 'when user does not have permission' do
      it 'returns a resource not available error' do
        expect(resolve_configuration).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when project is not found' do
      let(:project_id) { "gid://gitlab/Project/#{non_existing_record_id}" }

      it 'returns a resource not available error' do
        expect(resolve_configuration).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user is not authenticated' do
      let(:current_user) { nil }

      it 'returns a resource not available error' do
        expect(resolve_configuration).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
