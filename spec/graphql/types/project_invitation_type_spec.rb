# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::ProjectInvitationType do
  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Project) }

  specify { expect(described_class.graphql_name).to eq('ProjectInvitation') }

  specify { expect(described_class).to require_graphql_authorizations(:admin_project) }

  it 'has the expected fields' do
    expected_fields = %w[
      access_level created_by created_at updated_at expires_at project user
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
