# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineMessageType, feature_category: :continuous_integration do
  specify { expect(described_class.graphql_name).to eq('PipelineMessage') }

  it 'contains attributes related to a pipeline message' do
    expected_fields = %w[
      id content
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
