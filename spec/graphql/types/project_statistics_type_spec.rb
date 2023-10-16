# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ProjectStatistics'] do
  it 'has the expected fields' do
    expect(described_class).to include_graphql_fields(
      :storage_size, :repository_size, :lfs_objects_size,
      :build_artifacts_size, :packages_size, :commit_count,
      :wiki_size, :snippets_size, :pipeline_artifacts_size,
      :uploads_size, :container_registry_size
    )
  end
end
