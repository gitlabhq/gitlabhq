# frozen_string_literal: true

module Gitlab
  module CollaborativeEditing
    class DocumentStore
      TTL = 1.hour

      COMPACTION_THRESHOLD = 500
      SEED_CLAIM_TTL = 30.seconds
      COMPACTION_CLAIM_TTL = 30.seconds

      def initialize(document_key)
        @document_key = document_key
      end

      def updates
        with_redis { |redis| redis.lrange(updates_key, 0, -1) }
      end

      def append(update)
        length = with_redis do |redis|
          redis.multi do |multi|
            multi.rpush(updates_key, update)
            multi.expire(updates_key, TTL.to_i)
          end.first
        end

        length >= COMPACTION_THRESHOLD && claim_compaction
      end

      def replace(snapshot)
        with_redis do |redis|
          redis.multi do |multi|
            multi.del(updates_key)
            multi.rpush(updates_key, snapshot)
            multi.expire(updates_key, TTL.to_i)
            multi.del(compaction_key)
          end
        end
      end

      def claim_seed
        with_redis do |redis|
          redis.set(seed_key, '1', ex: SEED_CLAIM_TTL.to_i, nx: true)
        end
      end

      private

      attr_reader :document_key

      def claim_compaction
        with_redis do |redis|
          redis.set(compaction_key, '1', ex: COMPACTION_CLAIM_TTL.to_i, nx: true)
        end
      end

      def updates_key
        "collaborative_editing:{#{document_key}}:updates"
      end

      def seed_key
        "collaborative_editing:{#{document_key}}:seed"
      end

      def compaction_key
        "collaborative_editing:{#{document_key}}:compaction"
      end

      def with_redis(&block)
        Gitlab::Redis::SharedState.with(&block) # rubocop:disable CodeReuse/ActiveRecord -- Redis client, not ActiveRecord
      end
    end
  end
end
