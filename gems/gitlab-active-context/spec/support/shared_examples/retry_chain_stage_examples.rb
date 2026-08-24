# frozen_string_literal: true

RSpec.shared_examples 'a retry chain stage' do |queue_name:, delay:, next_queue:|
  it 'uses default values' do
    expect(described_class.number_of_shards).to eq(1)
    expect(described_class.shard_limit).to eq(1000)
  end

  describe '.queues' do
    it 'includes the queue' do
      expect(ActiveContext::Queues.queues).to include("activecontext:{#{queue_name}}")
    end
  end

  describe '.preprocess_options' do
    it 'includes skip_missing_content: true so missing content is dropped rather than retried' do
      expect(described_class.preprocess_options).to eq({
        queue_name: queue_name,
        skip_missing_content: true
      })
    end
  end

  describe '.processing_delay' do
    it 'returns the delay so transient errors can clear before the retry' do
      expect(described_class.processing_delay).to eq(delay)
    end
  end

  describe '.failure_queue' do
    it 'sends failures to the next stage of the chain' do
      expect(described_class.failure_queue).to eq(next_queue)
    end
  end
end
