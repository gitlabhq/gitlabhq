# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineScheduleSortEnum, feature_category: :continuous_integration do
  specify { expect(described_class.graphql_name).to eq('PipelineScheduleSort') }

  it 'exposes all the existing pipeline schedule sort values' do
    expect(described_class.values.keys).to contain_exactly(
      *%w[ID_DESC ID_ASC DESCRIPTION_DESC DESCRIPTION_ASC REF_ASC REF_DESC
        NEXT_RUN_AT_DESC NEXT_RUN_AT_ASC CREATED_AT_DESC CREATED_AT_ASC
        UPDATED_AT_DESC UPDATED_AT_ASC]
    )
  end

  it 'exposes only sort values that are supported by the pipeline schedule model' do
    expect(Ci::PipelineSchedule::SORT_ORDERS.keys).to include(
      *described_class.values.values.map(&:value)
    )
  end
end
