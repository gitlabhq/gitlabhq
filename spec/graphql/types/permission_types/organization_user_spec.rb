# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::OrganizationUser, feature_category: :cell do
  it do
    expected_permissions = [
      :remove_user
    ]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
