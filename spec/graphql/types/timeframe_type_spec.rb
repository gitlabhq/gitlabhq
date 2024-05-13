# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Timeframe'] do
  let(:input) { { start: "2018-06-04", end: "2020-10-06" } }
  let(:output) { { start: Date.parse(input[:start]), end: Date.parse(input[:end]) } }

  subject(:prepared_input) { described_class.coerce_isolated_input(input).prepare.to_h }

  it 'coerces ISO-dates into Time objects' do
    expect(prepared_input).to eq(output)
  end

  it 'rejects invalid input' do
    input[:start] = 'foo'

    expect { prepared_input }.to raise_error(GraphQL::CoercionError)
  end

  it 'accepts times as input' do
    input[:start] = '2018-06-04T13:48:14Z'

    expect(prepared_input).to eq(output)
  end

  it 'requires both ends of the range' do
    types = described_class.arguments.slice('start', 'end').values.map(&:type)

    expect(types).to all(be_non_null)
  end

  it 'rejects invalid range' do
    input.merge!(start: input[:end], end: input[:start])

    expect { prepared_input }.to raise_error(::Gitlab::Graphql::Errors::ArgumentError, 'start must be before end')
  end
end
