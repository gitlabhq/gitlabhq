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
      sidebar work_item_description_templates ci_cd_settings avatar_url link_paths licensed_features
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_namespace) }

  describe '.authorization_scopes' do
    it 'allows ai_workflows scope token' do
      expect(described_class.authorization_scopes).to include(:ai_workflows)
    end
  end

  describe 'fields with :ai_workflows scope' do
    %w[id fullPath workItem workItems].each do |field_name|
      it "includes :ai_workflows scope for the #{field_name} field" do
        field = described_class.fields[field_name]
        expect(field.instance_variable_get(:@scopes)).to include(:ai_workflows)
      end
    end
  end
end
