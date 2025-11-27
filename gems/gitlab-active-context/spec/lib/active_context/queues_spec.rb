# frozen_string_literal: true

RSpec.describe ActiveContext::Queues do
  let(:test_queue_class) do
    Class.new do
      include ActiveContext::Concerns::Queue

      def self.name
        "TestModule::TestQueue"
      end

      def self.number_of_shards
        3
      end
    end
  end

  let(:redis) { instance_double(Redis) }

  before do
    stub_const('TestModule::TestQueue', test_queue_class)
    allow(ActiveContext::Redis).to receive(:with_redis).and_yield(redis)

    described_class.instance_variable_set(:@queues, nil)
    described_class.instance_variable_set(:@raw_queues, nil)
    described_class.instance_variable_set(:@queues_registered, nil)
  end

  describe '.register!' do
    it 'registers the queue class' do
      expect(described_class.queues).to contain_exactly('activecontext:{retry_queue}')
      expect(described_class.raw_queues.size).to eq(1)

      described_class.register!(test_queue_class)

      expect(described_class.queues.size).to eq(2)
      expect(described_class.queues).to include('testmodule:{test_queue}')
    end

    it 'creates instances for each shard' do
      expect { described_class.register!(test_queue_class) }.to change { described_class.raw_queues.size }.by(3)

      raw_queues = described_class.raw_queues
      expect(raw_queues.size).to eq(4)
      test_queue_instances = raw_queues.select { |q| q.is_a?(test_queue_class) }
      expect(test_queue_instances.size).to eq(3)
      expect(test_queue_instances.map(&:shard)).to eq([0, 1, 2])
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

  describe 'configured queues registration' do
    before do
      allow(ActiveContext::Config).to receive(:queue_classes).and_return(
        [
          test_queue_class,
          Test::Queues::Mock
        ]
      )
    end

    def length_raw_queues_for_class(klass)
      described_class.raw_queues.count { |q| q.is_a?(klass) }
    end

    describe '.configured_queue_classes' do
      it 'returns the configured queued classes' do
        expect(described_class.configured_queue_classes).to eq ActiveContext::Config.queue_classes
      end
    end

    describe '.register_all_queues!' do
      it 'registers all configured queues' do
        described_class.register_all_queues!

        expect(described_class.queues).to eq Set.new(['testmodule:{test_queue}', "test_queues:{mock}",
          "activecontext:{retry_queue}"])

        expect(described_class.raw_queues.length).to eq 8
        expect(length_raw_queues_for_class(Test::Queues::Mock)).to eq Test::Queues::Mock.number_of_shards
        expect(length_raw_queues_for_class(test_queue_class)).to eq test_queue_class.number_of_shards
      end

      it 'only calls register! for each queue class once' do
        allow(described_class).to receive(:register!).and_call_original
        expect(described_class).to receive(:register!).with(Test::Queues::Mock).once
        expect(described_class).to receive(:register!).with(test_queue_class).once
        expect(described_class).to receive(:register!).with(ActiveContext::RetryQueue).once

        described_class.register_all_queues!
        described_class.register_all_queues!
        described_class.register_all_queues!
      end
    end

    context 'when calling .raw_queues' do
      it 'calls register_all_queues!' do
        expect(described_class).to receive(:register_all_queues!).at_least(:once).and_call_original

        expect(described_class.raw_queues.length).to eq 8
        expect(length_raw_queues_for_class(Test::Queues::Mock)).to eq Test::Queues::Mock.number_of_shards
        expect(length_raw_queues_for_class(test_queue_class)).to eq test_queue_class.number_of_shards
      end
    end

    context 'when calling .queues' do
      it 'calls register_all_queues!' do
        expect(described_class).to receive(:register_all_queues!).at_least(:once).and_call_original

        expect(described_class.queues).to eq Set.new(['testmodule:{test_queue}', "test_queues:{mock}",
          "activecontext:{retry_queue}"])
      end
    end
  end

  describe '.all_queued_items' do
    before do
      allow(ActiveContext::Config).to receive(:queue_classes).and_return(
        [
          test_queue_class,
          Test::Queues::Mock
        ]
      )
    end

    it 'picks up all the queued items' do
      allow(ActiveContext::Hasher).to receive(:consistent_hash).and_return(0, 1, 0)

      expect(redis).to receive(:incrby).with('testmodule:{test_queue}:0:score', 1).and_return(1)
      expect(redis).to receive(:incrby).with('test_queues:{mock}:0:score', 1).and_return(3)
      expect(redis).to receive(:incrby).with('test_queues:{mock}:1:score', 1).and_return(2)
      expect(redis).to receive(:zadd).with('testmodule:{test_queue}:0:zset', [[1, 'ref1']])
      expect(redis).to receive(:zadd).with('test_queues:{mock}:0:zset', [[3, 'ref3']])
      expect(redis).to receive(:zadd).with('test_queues:{mock}:1:zset', [[2, 'ref2']])

      allow(redis).to receive(:zrangebyscore).and_return([])
      expect(redis).to receive(:zrangebyscore)
        .with('testmodule:{test_queue}:0:zset', '-inf', '+inf')
        .and_return([['ref1', 1]])
      expect(redis).to receive(:zrangebyscore)
        .with('test_queues:{mock}:0:zset', '-inf', '+inf')
        .and_return([['ref3', 3]])
      expect(redis).to receive(:zrangebyscore)
        .with('test_queues:{mock}:1:zset', '-inf', '+inf')
        .and_return([['ref2', 2]])

      test_queue_class.push(['ref1'])
      Test::Queues::Mock.push(%w[ref2 ref3])

      expect(described_class.all_queued_items).to eq({
        'testmodule:{test_queue}:0:zset' => [['ref1', 1]],
        'test_queues:{mock}:0:zset' => [['ref3', 3]],
        'test_queues:{mock}:1:zset' => [['ref2', 2]]
      })
    end
  end

  describe '.queue_counts' do
    before do
      allow(ActiveContext::Config).to receive(:queue_classes).and_return([test_queue_class])
    end

    it 'returns counts for all queue shards' do
      allow(redis).to receive(:zcard).with('testmodule:{test_queue}:0:zset').and_return(4)
      allow(redis).to receive(:zcard).with('testmodule:{test_queue}:1:zset').and_return(0)
      allow(redis).to receive(:zcard).with('testmodule:{test_queue}:2:zset').and_return(2)
      allow(redis).to receive(:zcard).with('activecontext:{retry_queue}:0:zset').and_return(0)

      result = described_class.queue_counts

      expect(result).to contain_exactly(
        { queue_name: 'TestModule::TestQueue', shard: 0, count: 4 },
        { queue_name: 'TestModule::TestQueue', shard: 1, count: 0 },
        { queue_name: 'TestModule::TestQueue', shard: 2, count: 2 },
        { queue_name: 'ActiveContext::RetryQueue', shard: 0, count: 0 }
      )
    end

    it 'returns an empty array when no queues are registered' do
      allow(ActiveContext::Config).to receive(:queue_classes).and_return([])
      allow(redis).to receive(:zcard).with('activecontext:{retry_queue}:0:zset').and_return(0)

      expect(described_class.queue_counts).to eq([
        { queue_name: 'ActiveContext::RetryQueue', shard: 0, count: 0 }
      ])
    end
  end
end
