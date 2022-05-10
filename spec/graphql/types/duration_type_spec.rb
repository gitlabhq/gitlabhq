# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Duration'] do
  let(:duration) { 17.minutes }

  it 'presents information as a floating point number' do
    expect(described_class.coerce_isolated_result(duration)).to eq(duration.to_f)
  end

  it 'accepts integers as input' do
    expect(described_class.coerce_isolated_input(100)).to eq(100.0)
  end

  it 'accepts floats as input' do
    expect(described_class.coerce_isolated_input(0.5)).to eq(0.5)
  end

  it 'rejects nil' do
    expect { described_class.coerce_isolated_input(nil) }
      .to raise_error(GraphQL::CoercionError)
  end
end
