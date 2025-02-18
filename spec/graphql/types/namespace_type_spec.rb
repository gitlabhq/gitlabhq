# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Namespace'] do
  specify { expect(described_class.graphql_name).to eq('Namespace') }

  specify { expect(described_class.interfaces).to include(Types::TodoableInterface) }

  it 'has the expected fields' do
    expected_fields = %w[
      id name path full_name full_path achievements_path description description_html visibility
      lfs_enabled request_access_enabled projects root_storage_statistics shared_runners_setting
      timelog_categories achievements work_item pages_deployments import_source_users work_item_types
      sidebar work_item_description_templates allowed_custom_statuses ci_cd_settings
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_namespace) }
end
