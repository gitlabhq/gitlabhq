# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::PipelineSchedule::VariableInputType, feature_category: :ci_variables do
  specify { expect(described_class.graphql_name).to eq('PipelineScheduleVariableInput') }

  it { expect(described_class.arguments.keys).to match_array(%w[id key value variableType destroy]) }
end
