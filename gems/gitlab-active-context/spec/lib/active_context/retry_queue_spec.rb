# frozen_string_literal: true

RSpec.describe ActiveContext::RetryQueue do
  it 'uses default values' do
    expect(described_class.number_of_shards).to eq(1)
    expect(described_class.shard_limit).to eq(1000)
  end

  describe '.queues' do
    it 'includes the retry queue' do
      expect(ActiveContext::Queues.queues).to include('activecontext:{retry_queue}')
    end
  end
end
