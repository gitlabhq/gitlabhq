require 'spec_helper'

describe GitlabSchema.types['Issue'] do
  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Issue) }

  it { expect(described_class.graphql_name).to eq('Issue') }

  it { expect(described_class).to require_graphql_authorizations(:read_issue) }

  it 'has specific fields' do
    %i[relative_position web_path web_url reference].each do |field_name|
      expect(described_class).to have_graphql_field(field_name)
    end
  end
end
