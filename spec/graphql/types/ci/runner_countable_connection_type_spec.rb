# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::RunnerCountableConnectionType, feature_category: :fleet_visibility do
  it 'contains attributes related to a runner connection' do
    expected_fields = %w[count]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
