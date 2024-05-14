# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Deployment'], feature_category: :continuous_delivery do
  specify { expect(described_class.graphql_name).to eq('Deployment') }
  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Deployment) }

  it 'has the expected fields' do
    expected_fields = %w[
      id iid ref tag tags sha created_at updated_at finished_at status commit job triggerer userPermissions webPath
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_deployment) }
end
