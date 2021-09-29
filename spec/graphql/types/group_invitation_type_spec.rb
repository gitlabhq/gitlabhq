# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::GroupInvitationType do
  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Group) }

  specify { expect(described_class.graphql_name).to eq('GroupInvitation') }

  specify { expect(described_class).to require_graphql_authorizations(:admin_group) }

  it 'has the expected fields' do
    expected_fields = %w[
      email access_level created_by created_at updated_at expires_at group
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
