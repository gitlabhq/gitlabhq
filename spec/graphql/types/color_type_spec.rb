# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::ColorType do
  let(:hex) { '#663399' }
  let(:color_name) { 'rebeccapurple' }
  let(:color) { ::Gitlab::Color.of(hex) }
  let(:named_color) { ::Gitlab::Color.of(color_name) }

  specify { expect(described_class.graphql_name).to eq('Color') }

  it 'coerces Color object into hex string' do
    expect(described_class.coerce_isolated_result(color)).to eq(hex)
  end

  it 'coerces an hex string into Color object' do
    expect(described_class.coerce_isolated_input(hex)).to eq(color)
  end

  it 'coerces an named Color into hex string' do
    expect(described_class.coerce_isolated_result(named_color)).to eq(hex)
  end

  it 'coerces an named color into Color object' do
    expect(described_class.coerce_isolated_input(color_name)).to eq(named_color)
  end

  it 'rejects invalid input' do
    expect { described_class.coerce_isolated_input('not valid') }
      .to raise_error(GraphQL::CoercionError)
  end

  it 'rejects nil' do
    expect { described_class.coerce_isolated_input(nil) }
      .to raise_error(GraphQL::CoercionError)
  end
end
