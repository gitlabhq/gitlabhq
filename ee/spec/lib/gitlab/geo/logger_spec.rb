require 'spec_helper'

describe Gitlab::Geo::Logger do
  it 'uses the same log_level defined in Rails' do
    allow(Rails.logger).to receive(:level) { 99 }

    logger = described_class.build

    expect(logger.level).to eq(99)
  end
end
