# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineScheduleVariableType, feature_category: :continuous_integration do
  specify { expect(described_class.graphql_name).to eq('PipelineScheduleVariable') }
  specify { expect(described_class.interfaces).to contain_exactly(Types::Ci::VariableInterface) }
  specify { expect(described_class).to require_graphql_authorizations(:read_pipeline_schedule_variables) }

  it 'contains attributes related to a pipeline message' do
    expected_fields = %w[
      id key raw value variable_type
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
