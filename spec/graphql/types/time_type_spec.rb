require 'spec_helper'

describe GitlabSchema.types['Time'] do
  let(:float) { 1504630455.96215 }
  let(:time) { Time.at(float) }

  it { expect(described_class.name).to eq('Time') }

  it 'coerces Time into fractional seconds since epoch' do
    expect(described_class.coerce_isolated_result(time)).to eq(float)
  end

  it 'coerces fractional seconds since epoch into Time' do
    expect(described_class.coerce_isolated_input(float)).to eq(time)
  end
end
