# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::OrganizationUser, feature_category: :cell do
  it 'exposes the expected fields' do
    expected_permissions = %i[
      remove_user
      delete_user
      admin_organization
    ]

    expect(described_class).to have_graphql_fields(expected_permissions)
  end
end
