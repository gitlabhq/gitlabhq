# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::AnalyticsType do
  it 'exposes the expected fields' do
    expected_fields = %i[
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
