require 'spec_helper'

describe GitlabSchema.types['Project'] do
  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Project) }

  it { expect(described_class.graphql_name).to eq('Project') }

  it { expect(described_class).to require_graphql_authorizations(:read_project) }

  describe 'nested merge request' do
    it { expect(described_class).to have_graphql_field(:merge_requests) }
    it { expect(described_class).to have_graphql_field(:merge_request) }
  end

  describe 'nested issues' do
    it { expect(described_class).to have_graphql_field(:issues) }
  end

  it { is_expected.to have_graphql_field(:pipelines) }

  it { is_expected.to have_graphql_field(:repository) }

  it { is_expected.to have_graphql_field(:statistics) }
end
