# frozen_string_literal: true

RSpec.describe ActiveContext::Queues do
  before do
    described_class.instance_variable_set(:@queues, nil)
    described_class.instance_variable_set(:@raw_queues, nil)
  end

  describe '.register!' do
    it 'adds the queue key to queues set' do
      described_class.register!('test_queue', shards: 1)
      expect(described_class.queues).to include('test_queue')
    end

    it 'creates sharded queue names in raw_queues' do
      described_class.register!('test_queue', shards: 3)
      expected_raw_queues = ['test_queue:0', 'test_queue:1', 'test_queue:2']
      expect(described_class.raw_queues).to eq(expected_raw_queues)
    end

    it 'handles multiple queue registrations' do
      described_class.register!('queue1', shards: 2)
      described_class.register!('queue2', shards: 1)

      expect(described_class.queues).to eq(Set.new(%w[queue1 queue2]))
      expect(described_class.raw_queues).to eq(['queue1:0', 'queue1:1', 'queue2:0'])
    end

    it 'raises an error when register is called for the same key multiple times' do
      described_class.register!('test_queue', shards: 2)

      expect(described_class.queues).to eq(Set.new(['test_queue']))
      expect(described_class.raw_queues).to eq(['test_queue:0', 'test_queue:1'])

      expect { described_class.register!('test_queue', shards: 1) }.to raise_error(ArgumentError)
    end

    it 'appends new sharded queues to existing raw_queues' do
      described_class.register!('queue1', shards: 1)
      described_class.register!('queue2', shards: 2)

      expect(described_class.raw_queues).to eq(['queue1:0', 'queue2:0', 'queue2:1'])
    end
  end
end
