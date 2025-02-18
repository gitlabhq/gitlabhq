# frozen_string_literal: true

RSpec.describe ActiveContext::Queues do
  let(:test_queue_class) do
    Class.new do
      def self.name
        "TestModule::TestQueue"
      end

      def self.number_of_shards
        3
      end

      include ActiveContext::Concerns::Queue
    end
  end

  let(:redis) { instance_double(Redis) }

  before do
    stub_const('TestModule::TestQueue', test_queue_class)
    allow(ActiveContext::Redis).to receive(:with_redis).and_yield(redis)
    described_class.instance_variable_set(:@queues, nil)
    described_class.instance_variable_set(:@raw_queues, nil)
  end

  describe '.register!' do
    it 'registers the queue class' do
      expect(described_class.queues).to be_empty
      expect(described_class.raw_queues).to be_empty

      described_class.register!(test_queue_class)

      expect(described_class.queues.size).to eq(1)
      expect(described_class.queues.first).to eq('testmodule:{test_queue}')
    end

    it 'creates instances for each shard' do
      expect { described_class.register!(test_queue_class) }.to change { described_class.raw_queues.size }.by(3)

      raw_queues = described_class.raw_queues
      expect(raw_queues.size).to eq(3)
      expect(raw_queues.all?(test_queue_class)).to be true
      expect(raw_queues.map(&:shard)).to eq([0, 1, 2])
    end

    it 'does not register the same queue class twice' do
      described_class.register!(test_queue_class)
      expect { described_class.register!(test_queue_class) }.not_to change { described_class.queues.size }
      expect { described_class.register!(test_queue_class) }.not_to change { described_class.raw_queues.size }
    end

    it 'adds the correct key to the queues set' do
      described_class.register!(test_queue_class)
      expect(described_class.queues.first).to eq('testmodule:{test_queue}')
    end
  end
end
