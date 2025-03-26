# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['NamespaceProjectSort'], feature_category: :groups_and_projects do
  specify { expect(described_class.graphql_name).to eq('NamespaceProjectSort') }

  it 'exposes all the existing sort values' do
    expect(described_class.values.keys).to include(
      *%w[
        SIMILARITY
        ACTIVITY_DESC
        STORAGE_SIZE_ASC
        STORAGE_SIZE_DESC
        REPOSITORY_SIZE_ASC
        REPOSITORY_SIZE_DESC
        SNIPPETS_SIZE_ASC
        SNIPPETS_SIZE_DESC
        BUILD_ARTIFACTS_SIZE_ASC
        BUILD_ARTIFACTS_SIZE_DESC
        LFS_OBJECTS_SIZE_ASC
        LFS_OBJECTS_SIZE_DESC
        PACKAGES_SIZE_ASC
        PACKAGES_SIZE_DESC
        WIKI_SIZE_ASC
        WIKI_SIZE_DESC
        CONTAINER_REGISTRY_SIZE_ASC
        CONTAINER_REGISTRY_SIZE_DESC
      ]
    )
  end
end
