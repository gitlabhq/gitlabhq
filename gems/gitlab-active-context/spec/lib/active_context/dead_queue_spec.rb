# frozen_string_literal: true

RSpec.describe ActiveContext::DeadQueue do
  it 'uses default values' do
    expect(described_class.number_of_shards).to eq(1)
    expect(described_class.shard_limit).to eq(1000)
  end

  describe '.queues' do
    it 'does not include the dead queue' do
      expect(ActiveContext::Queues.queues).not_to include('activecontext:{dead_queue}')
    end
  end
end
