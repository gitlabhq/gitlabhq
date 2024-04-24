# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineScheduleStatusEnum, feature_category: :continuous_integration do
  specify { expect(described_class.graphql_name).to eq('PipelineScheduleStatus') }

  it 'exposes the status of a pipeline schedule' do
    expect(described_class.values.keys).to match_array(%w[ACTIVE INACTIVE])
  end
end
