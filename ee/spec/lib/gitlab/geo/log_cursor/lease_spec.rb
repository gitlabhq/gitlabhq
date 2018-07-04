require 'spec_helper'

describe Gitlab::Geo::LogCursor::Lease, :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  describe '.exclusive_lease' do
    it 'returns an exclusive lease instance' do
      expect(described_class.send(:exclusive_lease)).to be_an_instance_of(Gitlab::ExclusiveLease)
    end
  end

  describe '.renew!' do
    let(:lease) { stub_exclusive_lease(described_class::LEASE_KEY, renew: true) }

    before do
      allow(described_class).to receive(:exclusive_lease).and_return(lease)
    end

    it 'returns an exclusive lease instance' do
      expect(lease).to receive(:renew)

      described_class.renew!
    end

    it 'logs with the correct caller class' do
      stub_const("Gitlab::Geo::LogCursor::Logger::PID", 111)

      expect(::Gitlab::Logger).to receive(:debug).with(pid: 111,
                                                       class: 'Gitlab::Geo::LogCursor::Lease',
                                                       message: 'Lease renewed.')

      described_class.renew!
    end
  end

  describe '.try_obtain_lease_with_ttl' do
    it 'returns zero when there is no lease' do
      result = described_class.try_obtain_with_ttl {}

      expect(result[:ttl]).to eq(0)
      expect(result[:uuid]).to be_present
    end

    it 'returns > 0 if there is a lease' do
      allow(described_class).to receive(:try_obtain_with_ttl).and_return({ ttl: 1, uuid: false })

      result = described_class.try_obtain_with_ttl {}

      expect(result[:ttl]).to be > 0
      expect(result[:uuid]).to be false
    end

    it 'returns > 0 if there was an error' do
      lease = stub_exclusive_lease(described_class::LEASE_KEY, 'uuid')

      allow(lease).to receive(:try_obtain_with_ttl).and_return({ ttl: 0, uuid: 'uuid' })
      allow(described_class).to receive(:exclusive_lease).and_return(lease)

      expect_to_cancel_exclusive_lease(described_class::LEASE_KEY, 'uuid')

      result = described_class.try_obtain_with_ttl { raise StandardError }

      expect(result[:ttl]).to be > 0
      expect(result[:uuid]).to be false
    end
  end
end
