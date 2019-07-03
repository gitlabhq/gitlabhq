require 'spec_helper'

describe GitlabSchema.types['Metadata'] do
  it { expect(described_class.graphql_name).to eq('Metadata') }
  it { is_expected.to require_graphql_authorizations(:read_instance_metadata) }
end
