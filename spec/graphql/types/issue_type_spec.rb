require 'spec_helper'

describe GitlabSchema.types['Issue'] do
  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Issue) }

  it { expect(described_class.graphql_name).to eq('Issue') }
end
