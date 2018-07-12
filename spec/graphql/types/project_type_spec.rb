require 'spec_helper'

describe GitlabSchema.types['Project'] do
  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Project) }

  it { expect(described_class.graphql_name).to eq('Project') }

  describe 'nested merge request' do
    it { expect(described_class).to have_graphql_field(:merge_request) }

    it 'authorizes the merge request' do
      expect(described_class.fields['mergeRequest'])
        .to  require_graphql_authorizations(:read_merge_request)
    end
  end

  it { is_expected.to have_graphql_field(:pipelines) }
end
