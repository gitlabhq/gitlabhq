# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Strategy::RoundRobin, :clean_gitlab_redis_shared_state do
  subject(:round_robin) { described_class.new('_key_', %i[variant1 variant2]) }

  describe "execute" do
    context "when there are 2 variants" do
      it "proves out round robin in selection", :aggregate_failures do
        expect(round_robin.execute).to eq :variant2
        expect(round_robin.execute).to eq :variant1
        expect(round_robin.execute).to eq :variant2
      end
    end

    context "when there are more than 2 variants" do
      subject(:round_robin) { described_class.new('_key_', %i[variant1 variant2 variant3]) }

      it "proves out round robin in selection", :aggregate_failures do
        expect(round_robin.execute).to eq :variant2
        expect(round_robin.execute).to eq :variant3
        expect(round_robin.execute).to eq :variant1

        expect(round_robin.execute).to eq :variant2
        expect(round_robin.execute).to eq :variant3
        expect(round_robin.execute).to eq :variant1
      end
    end

    context "when writing to cache fails" do
      subject(:round_robin) { described_class.new('_key_', []) }

      it "raises an error and logs" do
        allow(Gitlab::Redis::SharedState).to receive(:with).and_raise(Strategy::RoundRobin::CacheError)
        expect(Gitlab::AppLogger).to receive(:warn)

        expect { round_robin.execute }.to raise_error(Strategy::RoundRobin::CacheError)
      end
    end
  end

  describe "#counter_expires_in" do
    it 'displays the expiration time in seconds' do
      round_robin.execute

      expect(round_robin.counter_expires_in).to be_between(0, described_class::COUNTER_EXPIRE_TIME)
    end
  end

  describe '#value' do
    it 'get the count' do
      expect(round_robin.counter_value).to eq(0)

      round_robin.execute

      expect(round_robin.counter_value).to eq(1)
    end
  end

  describe '#reset!' do
    it 'resets the count down to zero' do
      3.times { round_robin.execute }

      expect { round_robin.reset! }.to change { round_robin.counter_value }.from(3).to(0)
    end
  end
end
