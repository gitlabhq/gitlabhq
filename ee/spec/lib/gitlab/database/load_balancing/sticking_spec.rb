require 'spec_helper'

describe Gitlab::Database::LoadBalancing::Sticking, :redis do
  after do
    Gitlab::Database::LoadBalancing::Session.clear_session
  end

  describe '.stick_if_necessary' do
    context 'when sticking is disabled' do
      it 'does not perform any sticking' do
        expect(described_class).not_to receive(:stick)

        described_class.stick_if_necessary(:user, 42)
      end
    end

    context 'when sticking is enabled' do
      before do
        allow(Gitlab::Database::LoadBalancing).to receive(:enable?)
          .and_return(true)
      end

      it 'does not stick if no write was performed' do
        allow(Gitlab::Database::LoadBalancing::Session.current)
          .to receive(:performed_write?)
          .and_return(false)

        expect(described_class).not_to receive(:stick)

        described_class.stick_if_necessary(:user, 42)
      end

      it 'sticks to the primary if a write was performed' do
        allow(Gitlab::Database::LoadBalancing::Session.current)
          .to receive(:performed_write?)
          .and_return(true)

        expect(described_class).to receive(:stick).with(:user, 42)

        described_class.stick_if_necessary(:user, 42)
      end
    end
  end

  describe '.all_caught_up?' do
    let(:lb) { double(:lb) }

    before do
      allow(described_class).to receive(:load_balancer).and_return(lb)
    end

    it 'returns true if no write location could be found' do
      allow(described_class).to receive(:last_write_location_for)
        .with(:user, 42)
        .and_return(nil)

      expect(lb).not_to receive(:all_caught_up?)

      expect(described_class.all_caught_up?(:user, 42)).to eq(true)
    end

    it 'returns true, and unsticks if all secondaries have caught up' do
      allow(described_class).to receive(:last_write_location_for)
        .with(:user, 42)
        .and_return('foo')

      allow(lb).to receive(:all_caught_up?).with('foo').and_return(true)

      expect(described_class).to receive(:unstick).with(:user, 42)

      expect(described_class.all_caught_up?(:user, 42)).to eq(true)
    end

    it 'return false if the secondaries have not yet caught up' do
      allow(described_class).to receive(:last_write_location_for)
        .with(:user, 42)
        .and_return('foo')

      allow(lb).to receive(:all_caught_up?).with('foo').and_return(false)

      expect(described_class.all_caught_up?(:user, 42)).to eq(false)
    end
  end

  describe '.unstick_or_continue_sticking' do
    let(:lb) { double(:lb) }

    before do
      allow(described_class).to receive(:load_balancer).and_return(lb)
    end

    it 'simply returns if no write location could be found' do
      allow(described_class).to receive(:last_write_location_for)
        .with(:user, 42)
        .and_return(nil)

      expect(lb).not_to receive(:all_caught_up?)

      described_class.unstick_or_continue_sticking(:user, 42)
    end

    it 'unsticks if all secondaries have caught up' do
      allow(described_class).to receive(:last_write_location_for)
        .with(:user, 42)
        .and_return('foo')

      allow(lb).to receive(:all_caught_up?).with('foo').and_return(true)

      expect(described_class).to receive(:unstick).with(:user, 42)

      described_class.unstick_or_continue_sticking(:user, 42)
    end

    it 'continues using the primary if the secondaries have not yet caught up' do
      allow(described_class).to receive(:last_write_location_for)
        .with(:user, 42)
        .and_return('foo')

      allow(lb).to receive(:all_caught_up?).with('foo').and_return(false)

      expect(Gitlab::Database::LoadBalancing::Session.current)
        .to receive(:use_primary!)

      described_class.unstick_or_continue_sticking(:user, 42)
    end
  end

  describe '.stick' do
    context 'when sticking is disabled' do
      it 'does not perform any sticking' do
        expect(described_class).not_to receive(:set_write_location_for)

        described_class.stick(:user, 42)
      end
    end

    context 'when sticking is enabled' do
      it 'sticks an entity to the primary' do
        allow(Gitlab::Database::LoadBalancing).to receive(:enable?)
          .and_return(true)

        lb = double(:lb, primary_write_location: 'foo')

        allow(described_class).to receive(:load_balancer).and_return(lb)

        expect(described_class).to receive(:set_write_location_for)
          .with(:user, 42, 'foo')

        expect(Gitlab::Database::LoadBalancing::Session.current)
          .to receive(:use_primary!)

        described_class.stick(:user, 42)
      end
    end
  end

  describe '.unstick' do
    it 'removes the sticking data from Redis' do
      described_class.set_write_location_for(:user, 4, 'foo')
      described_class.unstick(:user, 4)

      expect(described_class.last_write_location_for(:user, 4)).to be_nil
    end
  end

  describe '.last_write_location_for' do
    it 'returns the last WAL write location for a user' do
      described_class.set_write_location_for(:user, 4, 'foo')

      expect(described_class.last_write_location_for(:user, 4)).to eq('foo')
    end
  end

  describe '.redis_key_for' do
    it 'returns a String' do
      expect(described_class.redis_key_for(:user, 42))
        .to eq('database-load-balancing/write-location/user/42')
    end
  end

  describe '.load_balancer' do
    it 'returns a the load balancer' do
      proxy = double(:proxy)

      expect(Gitlab::Database::LoadBalancing).to receive(:proxy)
        .and_return(proxy)

      expect(proxy).to receive(:load_balancer)

      described_class.load_balancer
    end
  end
end
