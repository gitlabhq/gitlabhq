# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::ProjectPlanLimitsType, feature_category: :api do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('ProjectPlanLimits') }

  it 'exposes the expected fields' do
    expected_fields = %i[ci_pipeline_schedules]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
