# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::Environment, feature_category: :continuous_delivery do
  it do
    expected_permissions = [
      :update_environment, :destroy_environment, :stop_environment
    ]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
