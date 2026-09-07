# frozen_string_literal: true

module Gitlab
  module CollaborativeEditing
    class DocumentStore
      TTL = 1.hour

      COMPACTION_THRESHOLD = 500
      SEED_CLAIM_TTL = 30.seconds
      COMPACTION_CLAIM_TTL = 30.seconds
      MAX_LOG_LENGTH = COMPACTION_THRESHOLD * 4

      FULL = 'full'

      Result = Struct.new(:full, :compaction_token, keyword_init: true) do
        alias_method :full?, :full

        def compact?
          compaction_token.present?
        end
      end

      APPEND_SCRIPT = <<~LUA
        local updates_key, claim_key = KEYS[1], KEYS[2]
        local update, token = ARGV[1], ARGV[2]
        local ttl, threshold, claim_ttl = tonumber(ARGV[3]), tonumber(ARGV[4]), tonumber(ARGV[5])
        local max_length = tonumber(ARGV[6])

        local length = redis.call('llen', updates_key)
        local full = length >= max_length

        if not full then
          length = redis.call('rpush', updates_key, update)
          redis.call('expire', updates_key, ttl)
        end

        if not full and length < threshold then
          return {}
        end

        if redis.call('set', claim_key, token .. ':' .. length, 'EX', claim_ttl, 'NX') then
          return { full and 'full' or '', token }
        end

        return { full and 'full' or '' }
      LUA

      REPLACE_SCRIPT = <<~LUA
        local updates_key, claim_key = KEYS[1], KEYS[2]
        local snapshot, token, ttl = ARGV[1], ARGV[2], tonumber(ARGV[3])

        local claim = redis.call('get', claim_key)
        if not claim then
          return 0
        end

        local claimed_token, claimed_length = string.match(claim, '^(.+):(%d+)$')
        if claimed_token ~= token then
          return 0
        end

        redis.call('ltrim', updates_key, tonumber(claimed_length), -1)
        redis.call('lpush', updates_key, snapshot)
        redis.call('expire', updates_key, ttl)
        redis.call('del', claim_key)

        return 1
      LUA

      def initialize(document_key)
        @document_key = document_key
      end

      def updates
        with_redis { |redis| redis.lrange(updates_key, 0, -1) }
      end

      def append(update)
        token = SecureRandom.hex(16)

        full, claimed = with_redis do |redis|
          redis.eval(
            APPEND_SCRIPT,
            keys: [updates_key, compaction_key],
            argv: [
              update, token, TTL.to_i, COMPACTION_THRESHOLD, COMPACTION_CLAIM_TTL.to_i, MAX_LOG_LENGTH
            ]
          )
        end

        Result.new(full: full == FULL, compaction_token: claimed.presence)
      end

      def replace(snapshot, token)
        return false if token.blank?

        result = with_redis do |redis|
          redis.eval(
            REPLACE_SCRIPT,
            keys: [updates_key, compaction_key],
            argv: [snapshot, token, TTL.to_i]
          )
        end

        result == 1
      end

      def claim_seed
        with_redis do |redis|
          redis.set(seed_key, '1', ex: SEED_CLAIM_TTL.to_i, nx: true)
        end
      end

      private

      attr_reader :document_key

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
