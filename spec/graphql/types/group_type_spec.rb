# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Group'] do
  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Group) }

  it { expect(described_class.graphql_name).to eq('Group') }

  it { expect(described_class).to require_graphql_authorizations(:read_group) }
end
