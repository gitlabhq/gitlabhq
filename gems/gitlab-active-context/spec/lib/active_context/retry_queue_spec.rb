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

  describe '.preprocess_options' do
    it 'returns skip_missing_content: true so missing content is skipped rather than sent to DeadQueue' do
      expect(described_class.preprocess_options).to eq({ skip_missing_content: true })
    end
  end
end
