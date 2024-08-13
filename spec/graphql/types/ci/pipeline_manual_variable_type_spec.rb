# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineManualVariableType, feature_category: :continuous_integration do
  specify { expect(described_class.graphql_name).to eq('PipelineManualVariable') }

  it 'contains attributes related to a variable' do
    expected_fields = %w[id key value]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
