# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['RootStorageStatistics'], feature_category: :consumables_cost_management do
  specify { expect(described_class.graphql_name).to eq('RootStorageStatistics') }

  it 'has the expected fields' do
    expect(described_class).to include_graphql_fields(:storage_size, :repository_size, :lfs_objects_size,
      :build_artifacts_size, :packages_size, :wiki_size, :snippets_size,
      :pipeline_artifacts_size, :uploads_size, :dependency_proxy_size,
      :container_registry_size, :container_registry_size_is_estimated, :registry_size_estimated)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_statistics) }
end
