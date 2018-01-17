require 'spec_helper'

describe Gitlab::Geo::Logger do
  it 'uses the same log_level defined in Rails' do
    allow(Rails.logger).to receive(:level) { 99 }
    expect_any_instance_of(::Gitlab::Geo::Logger).to receive(:level=).with(99)

    described_class.build
  end
end
