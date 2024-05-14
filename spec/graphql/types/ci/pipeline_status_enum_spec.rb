# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineStatusEnum, feature_category: :continuous_integration do
  it 'exposes all pipeline states' do
    expect(described_class.values.keys).to contain_exactly(
      *::Ci::Pipeline.all_state_names.map(&:to_s).map(&:upcase)
    )
  end
end
