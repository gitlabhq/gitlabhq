# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['RootStorageStatistics'] do
  it { expect(described_class.graphql_name).to eq('RootStorageStatistics') }

  it 'has all the required fields' do
    is_expected.to have_graphql_fields(:storage_size, :repository_size, :lfs_objects_size,
                                       :build_artifacts_size, :packages_size, :wiki_size)
  end

  it { is_expected.to require_graphql_authorizations(:read_statistics) }
end
