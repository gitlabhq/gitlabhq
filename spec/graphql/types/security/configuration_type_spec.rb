# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Security::ConfigurationType, feature_category: :security_asset_inventories do
  it 'has expected fields' do
    expect(described_class).to include_graphql_fields(
      :auto_devops_enabled,
      :auto_devops_help_page_path,
      :auto_devops_path,
      :can_enable_auto_devops,
      :can_enable_spp,
      :container_scanning_for_registry_enabled,
      :features,
      :gitlab_ci_history_path,
      :gitlab_ci_present,
      :help_page_path,
      :is_gitlab_com,
      :latest_pipeline_path,
      :license_configuration_source,
      :secret_detection_configuration_path,
      :secret_push_protection_available,
      :secret_push_protection_enabled,
      :secret_push_protection_licensed,
      :security_training_enabled,
      :user_is_project_admin,
      :validity_checks_available,
      :validity_checks_enabled,
      :vulnerability_training_docs_path,
      :upgrade_path,
      :group_full_path,
      :can_apply_profiles,
      :can_read_attributes,
      :can_manage_attributes,
      :group_manage_attributes_path
    )
  end
end
