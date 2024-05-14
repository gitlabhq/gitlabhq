# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineScopeEnum, feature_category: :continuous_integration do
  it 'exposes all pipeline scopes' do
    expect(described_class.values.keys).to contain_exactly(
      *::Ci::PipelinesFinder::ALLOWED_SCOPES.keys.map(&:to_s)
    )
  end
end
