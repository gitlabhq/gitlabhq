require 'spec_helper'

describe GitlabSchema.types['MergeRequest'] do
  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::MergeRequest) }

  describe 'head pipeline' do
    it 'has a head pipeline field' do
      expect(described_class).to have_graphql_field(:head_pipeline)
    end

    it 'authorizes the field' do
      expect(described_class.fields['headPipeline'])
        .to require_graphql_authorizations(:read_pipeline)
    end
  end
end
