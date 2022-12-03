# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::Deployment, feature_category: :continuous_delivery do
  it do
    expected_permissions = [
      :update_deployment, :destroy_deployment
    ]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
