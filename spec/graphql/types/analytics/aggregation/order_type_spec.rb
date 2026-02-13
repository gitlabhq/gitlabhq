# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Analytics::Aggregation::OrderType, feature_category: :database do
  specify { expect(described_class.graphql_name).to eq('AggregationOrder') }

  it 'has the correct arguments' do
    expect(described_class.arguments.keys).to match_array(%w[direction identifier parameters])
  end
end
