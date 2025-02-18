# frozen_string_literal: true

RSpec.describe ActiveContext::Concerns::Queue do
  let(:mock_queue_class) do
    Class.new do
      def self.name
        'MockModule::TestQueue'
      end

      def self.number_of_shards
        2
      end

      include ActiveContext::Concerns::Queue
    end
  end

  let(:redis_double) { instance_double(Redis) }

  before do
    clear_all_queues!
    allow(ActiveContext::Redis).to receive(:with_redis).and_yield(redis_double)
  end

  describe '.register!' do
    it 'registers the queue with ActiveContext::Queues' do
      mock_queue_class

      expect(ActiveContext::Queues.queues).to include(mock_queue_class.redis_key)
      expect(ActiveContext::Queues.raw_queues.size).to eq(2)
      expect(ActiveContext::Queues.raw_queues.all?(mock_queue_class)).to be true
    end
  end

  describe '.push' do
    it 'pushes references to Redis' do
      references = %w[ref1 ref2 ref3]

      allow(ActiveContext::Shard).to receive(:shard_number).and_return(0, 1, 0)
      expect(redis_double).to receive(:incrby).with('mockmodule:{test_queue}:0:score', 2).and_return(2)
      expect(redis_double).to receive(:incrby).with('mockmodule:{test_queue}:1:score', 1).and_return(1)
      expect(redis_double).to receive(:zadd).with('mockmodule:{test_queue}:0:zset', [[1, 'ref1'], [2, 'ref3']])
      expect(redis_double).to receive(:zadd).with('mockmodule:{test_queue}:1:zset', [[1, 'ref2']])

      mock_queue_class.push(references)
    end
  end

  describe '.queue_size' do
    it 'returns the total size of all shards' do
      expect(redis_double).to receive(:zcard).with('mockmodule:{test_queue}:0:zset').and_return(5)
      expect(redis_double).to receive(:zcard).with('mockmodule:{test_queue}:1:zset').and_return(3)

      expect(mock_queue_class.queue_size).to eq(8)
    end
  end

  describe '.queued_items' do
    it 'returns items from all non-empty shards' do
      expect(redis_double).to receive(:zrangebyscore)
        .with('mockmodule:{test_queue}:0:zset', '-inf', '+inf', limit: [0, anything], with_scores: true)
        .and_return([['ref1', 1.0], ['ref2', 2.0]])
      expect(redis_double).to receive(:zrangebyscore)
        .with('mockmodule:{test_queue}:1:zset', '-inf', '+inf', limit: [0, anything], with_scores: true)
        .and_return([])

      expect(mock_queue_class.queued_items).to eq({
        0 => [['ref1', 1.0], ['ref2', 2.0]]
      })
    end
  end

  describe '.clear_tracking!' do
    # rubocop: disable RSpec/VerifiedDoubleReference -- stubbing GitLab logic
    let(:redis_cluster_validator) { class_double("Gitlab::Instrumentation::RedisClusterValidator").as_stubbed_const }
    let(:redis_cluster_util) { class_double("Gitlab::Redis::ClusterUtil").as_stubbed_const }
    # rubocop: enable RSpec/VerifiedDoubleReference

    before do
      allow(redis_cluster_validator).to receive(:allow_cross_slot_commands).and_yield
    end

    context 'when Redis is not in cluster mode' do
      before do
        allow(redis_cluster_util).to receive(:cluster?).and_return(false)
      end

      it 'calls unlink directly on redis' do
        expect(redis_double).to receive(:unlink)
          .with(
            'mockmodule:{test_queue}:0:zset', 'mockmodule:{test_queue}:0:score',
            'mockmodule:{test_queue}:1:zset', 'mockmodule:{test_queue}:1:score'
          )

        mock_queue_class.clear_tracking!
      end
    end

    context 'when Redis is in cluster mode' do
      before do
        allow(redis_cluster_util).to receive(:cluster?).and_return(true)
      end

      it 'calls batch_unlink on ClusterUtil' do
        expect(redis_cluster_util).to receive(:batch_unlink)
          .with(
            [
              'mockmodule:{test_queue}:0:zset', 'mockmodule:{test_queue}:0:score',
              'mockmodule:{test_queue}:1:zset', 'mockmodule:{test_queue}:1:score'
            ],
            redis_double
          )

        mock_queue_class.clear_tracking!
      end
    end
  end

  describe '.redis_key' do
    it 'returns the correct Redis key' do
      expect(mock_queue_class.redis_key).to eq('mockmodule:{test_queue}')
    end
  end

  def clear_all_queues!
    ActiveContext::Queues.instance_variable_set(:@queues, Set.new)
    ActiveContext::Queues.instance_variable_set(:@raw_queues, [])
  end
end
