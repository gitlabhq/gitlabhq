# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::AnalyticsType, feature_category: :fleet_visibility do
  it 'exposes the expected fields' do
    expected_fields = %i[
      aggregate
      time_series

      weekPipelinesTotals
      weekPipelinesLabels
      weekPipelinesSuccessful
      monthPipelinesLabels
      monthPipelinesTotals
      monthPipelinesSuccessful
      yearPipelinesLabels
      yearPipelinesTotals
      yearPipelinesSuccessful
      pipelineTimesLabels
      pipelineTimesValues
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
