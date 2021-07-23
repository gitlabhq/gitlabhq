# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::RangeInputType do
  let(:of_integer) { ::GraphQL::Types::Int }

  context 'parameterized on Integer' do
    let(:type) { described_class[of_integer] }

    it 'accepts start and end' do
      input = { start: 1, end: 10 }
      output = { start: 1, end: 10 }

      expect(type.coerce_isolated_input(input)).to eq(output)
    end

    it 'rejects inverted ranges' do
      input = { start: 10, end: 1 }

      expect { type.coerce_isolated_input(input) }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
    end
  end

  it 'follows expected subtyping relationships for instances' do
    context = GraphQL::Query::Context.new(
      query: OpenStruct.new(schema: nil),
      values: {},
      object: nil
    )
    instance = described_class[of_integer].new(context: context, defaults_used: [], ruby_kwargs: {})

    expect(instance).to be_a_kind_of(described_class)
    expect(instance).to be_a_kind_of(described_class[of_integer])
    expect(instance).not_to be_a_kind_of(described_class[GraphQL::Types::ID])
  end

  it 'follows expected subtyping relationships for classes' do
    expect(described_class[of_integer]).to be < described_class
    expect(described_class[of_integer]).not_to be < described_class[GraphQL::Types::ID]
    expect(described_class[of_integer]).not_to be < described_class[of_integer, false]
  end
end
