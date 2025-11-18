# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TimestampRange'], feature_category: :shared do
  let(:input) { { start: "2025-10-03T17:05:33Z", end: "2025-10-08T10:45:53Z" } }
  let(:output) { { start: Time.parse(input[:start]), end: Time.parse(input[:end]) } }

  subject(:prepared_input) { described_class.coerce_isolated_input(input).prepare.to_h }

  it 'coerces ISO-times into Time objects' do
    expect(prepared_input).to eq(output)
  end

  it 'rejects invalid input' do
    input[:start] = 'foo'

    expect { prepared_input }.to raise_error(GraphQL::CoercionError)
  end

  it 'accepts dates as input' do
    input[:start] = '2018-10-03'

    expect(prepared_input).to eq(output)
  end

  it 'requires both ends of the range' do
    types = described_class.arguments.slice('start', 'end').values.map(&:type)

    expect(types).to all(be_non_null)
  end

  it 'rejects start time before end time' do
    input.merge!(start: input[:end], end: input[:start])

    expect { prepared_input }.to raise_error(::Gitlab::Graphql::Errors::ArgumentError, 'start must be before end')
  end

  it 'rejects equal start and end times' do
    input.merge!(start: input[:start], end: input[:start])

    expect { prepared_input }.to raise_error(::Gitlab::Graphql::Errors::ArgumentError, 'start must be before end')
  end
end
