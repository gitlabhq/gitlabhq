require 'spec_helper'

describe GitlabSchema.types['MergeRequest'] do
  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::MergeRequest) }

  it { expect(described_class).to require_graphql_authorizations(:read_merge_request) }

  describe 'nested head pipeline' do
    it { expect(described_class).to have_graphql_field(:head_pipeline) }
  end
end
