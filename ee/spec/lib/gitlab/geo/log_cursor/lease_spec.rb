require 'spec_helper'

describe Gitlab::Geo::LogCursor::Lease, :clean_gitlab_redis_shared_state do
  describe '.exclusive_lease' do
    it 'returns an exclusive lease instance' do
      expect(described_class.send(:exclusive_lease)).to be_an_instance_of(Gitlab::ExclusiveLease)
    end
  end

  describe '.renew!' do
    it 'returns an exclusive lease instance' do
      expect_any_instance_of(Gitlab::ExclusiveLease).to receive(:renew)

      described_class.renew!
    end

    it 'logs with the correct caller class' do
      stub_const("Gitlab::Geo::LogCursor::Logger::PID", 111)
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:renew).and_return(true)

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
      expect(Gitlab::ExclusiveLease).to receive(:cancel)

      result = described_class.try_obtain_with_ttl { raise StandardError }

      expect(result[:ttl]).to be > 0
      expect(result[:uuid]).to be false
    end
  end
end
