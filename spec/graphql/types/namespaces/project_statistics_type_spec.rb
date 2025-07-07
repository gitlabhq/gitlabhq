# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['NamespaceProjectStatistics'], feature_category: :groups_and_projects do
  it 'has the expected fields' do
    expect(described_class).to include_graphql_fields(
      :build_artifacts_size, :lfs_objects_size, :packages_size,
      :pipeline_artifacts_size, :repository_size, :snippets_size,
      :storage_size, :uploads_size, :wiki_size
    )
  end
end
