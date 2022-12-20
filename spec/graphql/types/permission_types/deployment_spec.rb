# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::Deployment, feature_category: :continuous_delivery do
  it do
    expected_permissions = %i[update_deployment destroy_deployment]

    expect(described_class).to include_graphql_fields(*expected_permissions)
  end
end
