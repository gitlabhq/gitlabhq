# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::InviteEmailExperiment, :clean_gitlab_redis_shared_state do
  subject(:invite_email) { experiment('members/invite_email', **context) }

  let(:context) { { actor: double('Member', created_by: double('User', avatar_url: '_avatar_url_')) } }

  before do
    allow(invite_email).to receive(:enabled?).and_return(true)
  end

  describe ".initial_invite_email?" do
    it "is an initial invite email" do
      expect(described_class.initial_invite_email?('initial_email')).to be(true)
    end

    it "is not an initial invite email" do
      expect(described_class.initial_invite_email?('_bogus_')).to be(false)
    end
  end

  describe "exclusions", :experiment do
    it "excludes when created by is nil" do
      expect(experiment('members/invite_email')).to exclude(actor: double(created_by: nil))
    end

    it "excludes when avatar_url is nil" do
      member_without_avatar_url = double('Member', created_by: double('User', avatar_url: nil))

      expect(experiment('members/invite_email')).to exclude(actor: member_without_avatar_url)
    end
  end

  describe "variant resolution" do
    it "proves out round robin in variant selection", :aggregate_failures do
      instance_1 = described_class.new('members/invite_email', **context)
      allow(instance_1).to receive(:enabled?).and_return(true)
      instance_2 = described_class.new('members/invite_email', **context)
      allow(instance_2).to receive(:enabled?).and_return(true)

      instance_1.try { }

      expect(instance_1.variant.name).to eq('control')

      instance_2.try { }

      expect(instance_2.variant.name).to eq('activity')
    end
  end

  describe Members::RoundRobin do
    subject(:round_robin) { Members::RoundRobin.new('_key_', %i[variant1 variant2]) }

    describe "execute" do
      context "when there are 2 variants" do
        it "proves out round robin in selection", :aggregate_failures do
          expect(round_robin.execute).to eq :variant2
          expect(round_robin.execute).to eq :variant1
          expect(round_robin.execute).to eq :variant2
        end
      end

      context "when there are more than 2 variants" do
        subject(:round_robin) { Members::RoundRobin.new('_key_', %i[variant1 variant2 variant3]) }

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
        subject(:round_robin) { Members::RoundRobin.new('_key_', []) }

        it "raises an error and logs" do
          allow(Gitlab::Redis::SharedState).to receive(:with).and_raise(Members::RoundRobin::CacheError)
          expect(Gitlab::AppLogger).to receive(:warn)

          expect { round_robin.execute }.to raise_error(Members::RoundRobin::CacheError)
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
end
