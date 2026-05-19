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
      mock_queue_class.register!

      expect(ActiveContext::Queues.queues).to include(mock_queue_class.redis_key)
      expect(ActiveContext::Queues.raw_queues.size).to eq(3)
      mock_queue_instances = ActiveContext::Queues.raw_queues.select { |q| q.is_a?(mock_queue_class) }
      expect(mock_queue_instances.size).to eq(2)
      expect(mock_queue_instances.all?(mock_queue_class)).to be true
    end
  end

  describe '.push' do
    it 'pushes references to Redis' do
      references = %w[ref1 ref2 ref3]

      allow(ActiveContext::Hasher).to receive(:consistent_hash).and_return(0, 1, 0)
      expect(redis_double).to receive(:incrby).with('mockmodule:{test_queue}:0:score', 2).and_return(2)
      expect(redis_double).to receive(:incrby).with('mockmodule:{test_queue}:1:score', 1).and_return(1)
      expect(redis_double).to receive(:zadd).with('mockmodule:{test_queue}:0:zset', [[1, 'ref1'], [2, 'ref3']])
      expect(redis_double).to receive(:zadd).with('mockmodule:{test_queue}:1:zset', [[1, 'ref2']])

      mock_queue_class.push(references)
    end
  end

  describe '.queue_size' do
    before do
      allow(mock_queue_class).to receive(:number_of_shards).and_return(3)

      allow(redis_double).to receive(:zcard).with('mockmodule:{test_queue}:0:zset').and_return(5)
      allow(redis_double).to receive(:zcard).with('mockmodule:{test_queue}:1:zset').and_return(3)
      allow(redis_double).to receive(:zcard).with('mockmodule:{test_queue}:2:zset').and_return(0)
      allow(redis_double).to receive(:zcard).with('mockmodule:{test_queue}:3:zset').and_return(7)
    end

    it 'returns the total size of all shards' do
      expect(redis_double).to receive(:zcard).with('mockmodule:{test_queue}:0:zset')
      expect(redis_double).to receive(:zcard).with('mockmodule:{test_queue}:1:zset')
      expect(redis_double).to receive(:zcard).with('mockmodule:{test_queue}:2:zset')

      expect(mock_queue_class.queue_size).to eq(8)
    end

    context 'when `shards` is given' do
      it 'returns the total size of the given `shards` within the configured `number_of_shards`' do
        expect(redis_double).to receive(:zcard).with('mockmodule:{test_queue}:0:zset')

        expect(redis_double).not_to receive(:zcard).with('mockmodule:{test_queue}:1:zset')
        expect(redis_double).not_to receive(:zcard).with('mockmodule:{test_queue}:2:zset')
        expect(redis_double).not_to receive(:zcard).with('mockmodule:{test_queue}:3:zset')

        expect(mock_queue_class.queue_size(shards: [0, 3])).to eq(5)
      end

      context 'when `include_orphaned` is set to true' do
        it 'returns the total size of the given `shards` without checking the `number_of_shards`' do
          expect(redis_double).to receive(:zcard).with('mockmodule:{test_queue}:0:zset')
          expect(redis_double).to receive(:zcard).with('mockmodule:{test_queue}:3:zset')

          expect(redis_double).not_to receive(:zcard).with('mockmodule:{test_queue}:1:zset')
          expect(redis_double).not_to receive(:zcard).with('mockmodule:{test_queue}:2:zset')

          expect(mock_queue_class.queue_size(shards: [0, 3], include_orphaned: true)).to eq(12)
        end
      end
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

  describe '.each_queued_items_by_shard' do
    before do
      allow(mock_queue_class).to receive_messages(
        number_of_shards: 3,
        shard_limit: 10
      )

      allow(redis_double).to receive(:zrangebyscore)
        .with('mockmodule:{test_queue}:0:zset', any_args)
        .and_return([['ref1', 1.0], ['ref2', 2.0]])
      allow(redis_double).to receive(:zrangebyscore)
        .with('mockmodule:{test_queue}:1:zset', any_args)
        .and_return([])
      allow(redis_double).to receive(:zrangebyscore)
        .with('mockmodule:{test_queue}:2:zset', any_args)
        .and_return([['ref3', 1.0]])
      allow(redis_double).to receive(:zrangebyscore)
        .with('mockmodule:{test_queue}:3:zset', any_args)
        .and_return([['ref4', 1.0]])
    end

    it 'yields items from all shards' do
      expect(redis_double).to receive(:zrangebyscore)
        .with('mockmodule:{test_queue}:0:zset', '-inf', '+inf', limit: [0, 10], with_scores: true)
      expect(redis_double).to receive(:zrangebyscore)
        .with('mockmodule:{test_queue}:1:zset', '-inf', '+inf', limit: [0, 10], with_scores: true)
      expect(redis_double).to receive(:zrangebyscore)
        .with('mockmodule:{test_queue}:2:zset', '-inf', '+inf', limit: [0, 10], with_scores: true)

      expect do |block|
        mock_queue_class.each_queued_items_by_shard(redis_double, &block)
      end.to yield_successive_args(
        [0, [['ref1', 1.0], ['ref2', 2.0]]],
        [1, []],
        [2, [['ref3', 1.0]]]
      )
    end

    context 'when `shards` is given' do
      it 'yields items from the given `shards` within the configured `number_of_shards`' do
        expect(redis_double).to receive(:zrangebyscore)
          .with('mockmodule:{test_queue}:0:zset', '-inf', '+inf', limit: [0, 10], with_scores: true)

        expect(redis_double).not_to receive(:zrangebyscore).with('mockmodule:{test_queue}:1:zset', any_args)
        expect(redis_double).not_to receive(:zrangebyscore).with('mockmodule:{test_queue}:2:zset', any_args)
        expect(redis_double).not_to receive(:zrangebyscore).with('mockmodule:{test_queue}:3:zset', any_args)

        expect do |block|
          mock_queue_class.each_queued_items_by_shard(redis_double, shards: [0, 3], &block)
        end.to yield_successive_args(
          [0, [['ref1', 1.0], ['ref2', 2.0]]]
        )
      end

      context 'when `include_orphaned` is set to true' do
        it 'yields items from the given `shards` without checking the `number_of_shards`' do
          expect(redis_double).to receive(:zrangebyscore)
            .with('mockmodule:{test_queue}:0:zset', '-inf', '+inf', limit: [0, 10], with_scores: true)
          expect(redis_double).to receive(:zrangebyscore)
            .with('mockmodule:{test_queue}:3:zset', '-inf', '+inf', limit: [0, 10], with_scores: true)

          expect(redis_double).not_to receive(:zrangebyscore).with('mockmodule:{test_queue}:1:zset', any_args)
          expect(redis_double).not_to receive(:zrangebyscore).with('mockmodule:{test_queue}:2:zset', any_args)

          expect do |block|
            mock_queue_class.each_queued_items_by_shard(redis_double, shards: [0, 3], include_orphaned: true, &block)
          end.to yield_successive_args(
            [0, [['ref1', 1.0], ['ref2', 2.0]]],
            [3, [['ref4', 1.0]]]
          )
        end
      end
    end

    context 'when `limit` is given' do
      it 'uses the `limit` for fetching the items' do
        expect(redis_double).to receive(:zrangebyscore)
          .with('mockmodule:{test_queue}:0:zset', '-inf', '+inf', limit: [0, 1], with_scores: true)
          .and_return([['ref1', 1.0]])
        expect(redis_double).to receive(:zrangebyscore)
          .with('mockmodule:{test_queue}:1:zset', '-inf', '+inf', limit: [0, 1], with_scores: true)
        expect(redis_double).to receive(:zrangebyscore)
          .with('mockmodule:{test_queue}:2:zset', '-inf', '+inf', limit: [0, 1], with_scores: true)

        expect do |block|
          mock_queue_class.each_queued_items_by_shard(redis_double, limit: 1, &block)
        end.to yield_successive_args(
          [0, [['ref1', 1.0]]],
          [1, []],
          [2, [['ref3', 1.0]]]
        )
      end
    end
  end

  describe '.remove_shard_items' do
    it 'removes the items in a given shard' do
      expect(redis_double).to receive(:zremrangebyscore).with(
        'mockmodule:{test_queue}:2:zset', 5.0, 12.0
      )

      mock_queue_class.remove_shard_items(redis_double, 2, 5.0, 12.0)
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

  describe '.preprocess_options' do
    it 'returns an empty hash by default' do
      expect(mock_queue_class.preprocess_options).to eq({})
    end

    context 'when a queue overrides preprocess_options' do
      let(:custom_queue_class) do
        Class.new do
          def self.name
            'CustomModule::CustomQueue'
          end

          def self.number_of_shards
            1
          end

          def self.preprocess_options
            { next_model_only: true }
          end

          include ActiveContext::Concerns::Queue
        end
      end

      it 'returns the custom options' do
        expect(custom_queue_class.preprocess_options).to eq({ next_model_only: true })
      end
    end
  end

  describe '.limit_throughput?' do
    it 'returns `false` by default' do
      expect(mock_queue_class.limit_throughput?).to be(false)
    end
  end

  describe '#redis_key' do
    it 'returns the correct Redis key' do
      expect(mock_queue_class.redis_key).to eq('mockmodule:{test_queue}')
    end
  end

  def clear_all_queues!
    ActiveContext::Queues.instance_variable_set(:@queues, Set.new)
    ActiveContext::Queues.instance_variable_set(:@raw_queues, [])
  end
end
