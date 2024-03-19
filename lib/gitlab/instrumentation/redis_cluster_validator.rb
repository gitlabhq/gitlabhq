# frozen_string_literal: true

require 'rails'
require 'redis-clustering'

module Gitlab
  module Instrumentation
    module RedisClusterValidator
      # Generate with:
      #
      # Gitlab::Redis::Cache
      #   .with { |redis| redis.call('COMMAND') }
      #   .select { |cmd| cmd[3] != 0 }
      #   .map { |cmd| [
      #                 cmd[0].upcase,
      #                 { first: cmd[3], last: cmd[4], step: cmd[5], single_key: cmd[3] == cmd[4] }
      #                ]
      #   }
      #   .sort_by(&:first)
      #   .to_h
      REDIS_COMMANDS = {
        "APPEND" => { first: 1, last: 1, step: 1, single_key: true },
        "BITCOUNT" => { first: 1, last: 1, step: 1, single_key: true },
        "BITFIELD" => { first: 1, last: 1, step: 1, single_key: true },
        "BITFIELD_RO" => { first: 1, last: 1, step: 1, single_key: true },
        "BITOP" => { first: 2, last: -1, step: 1, single_key: false },
        "BITPOS" => { first: 1, last: 1, step: 1, single_key: true },
        "BLMOVE" => { first: 1, last: 2, step: 1, single_key: false },
        "BLPOP" => { first: 1, last: -2, step: 1, single_key: false },
        "BRPOP" => { first: 1, last: -2, step: 1, single_key: false },
        "BRPOPLPUSH" => { first: 1, last: 2, step: 1, single_key: false },
        "BZPOPMAX" => { first: 1, last: -2, step: 1, single_key: false },
        "BZPOPMIN" => { first: 1, last: -2, step: 1, single_key: false },
        "COPY" => { first: 1, last: 2, step: 1, single_key: false },
        "DECR" => { first: 1, last: 1, step: 1, single_key: true },
        "DECRBY" => { first: 1, last: 1, step: 1, single_key: true },
        "DEL" => { first: 1, last: -1, step: 1, single_key: false },
        "DUMP" => { first: 1, last: 1, step: 1, single_key: true },
        "EXISTS" => { first: 1, last: -1, step: 1, single_key: false },
        "EXPIRE" => { first: 1, last: 1, step: 1, single_key: true },
        "EXPIREAT" => { first: 1, last: 1, step: 1, single_key: true },
        "GEOADD" => { first: 1, last: 1, step: 1, single_key: true },
        "GEODIST" => { first: 1, last: 1, step: 1, single_key: true },
        "GEOHASH" => { first: 1, last: 1, step: 1, single_key: true },
        "GEOPOS" => { first: 1, last: 1, step: 1, single_key: true },
        "GEORADIUS" => { first: 1, last: 1, step: 1, single_key: true },
        "GEORADIUSBYMEMBER" => { first: 1, last: 1, step: 1, single_key: true },
        "GEORADIUSBYMEMBER_RO" => { first: 1, last: 1, step: 1, single_key: true },
        "GEORADIUS_RO" => { first: 1, last: 1, step: 1, single_key: true },
        "GEOSEARCH" => { first: 1, last: 1, step: 1, single_key: true },
        "GEOSEARCHSTORE" => { first: 1, last: 2, step: 1, single_key: false },
        "GET" => { first: 1, last: 1, step: 1, single_key: true },
        "GETBIT" => { first: 1, last: 1, step: 1, single_key: true },
        "GETDEL" => { first: 1, last: 1, step: 1, single_key: true },
        "GETEX" => { first: 1, last: 1, step: 1, single_key: true },
        "GETRANGE" => { first: 1, last: 1, step: 1, single_key: true },
        "GETSET" => { first: 1, last: 1, step: 1, single_key: true },
        "HDEL" => { first: 1, last: 1, step: 1, single_key: true },
        "HEXISTS" => { first: 1, last: 1, step: 1, single_key: true },
        "HGET" => { first: 1, last: 1, step: 1, single_key: true },
        "HGETALL" => { first: 1, last: 1, step: 1, single_key: true },
        "HINCRBY" => { first: 1, last: 1, step: 1, single_key: true },
        "HINCRBYFLOAT" => { first: 1, last: 1, step: 1, single_key: true },
        "HKEYS" => { first: 1, last: 1, step: 1, single_key: true },
        "HLEN" => { first: 1, last: 1, step: 1, single_key: true },
        "HMGET" => { first: 1, last: 1, step: 1, single_key: true },
        "HMSET" => { first: 1, last: 1, step: 1, single_key: true },
        "HRANDFIELD" => { first: 1, last: 1, step: 1, single_key: true },
        "HSCAN" => { first: 1, last: 1, step: 1, single_key: true },
        "HSET" => { first: 1, last: 1, step: 1, single_key: true },
        "HSETNX" => { first: 1, last: 1, step: 1, single_key: true },
        "HSTRLEN" => { first: 1, last: 1, step: 1, single_key: true },
        "HVALS" => { first: 1, last: 1, step: 1, single_key: true },
        "INCR" => { first: 1, last: 1, step: 1, single_key: true },
        "INCRBY" => { first: 1, last: 1, step: 1, single_key: true },
        "INCRBYFLOAT" => { first: 1, last: 1, step: 1, single_key: true },
        "LINDEX" => { first: 1, last: 1, step: 1, single_key: true },
        "LINSERT" => { first: 1, last: 1, step: 1, single_key: true },
        "LLEN" => { first: 1, last: 1, step: 1, single_key: true },
        "LMOVE" => { first: 1, last: 2, step: 1, single_key: false },
        "LPOP" => { first: 1, last: 1, step: 1, single_key: true },
        "LPOS" => { first: 1, last: 1, step: 1, single_key: true },
        "LPUSH" => { first: 1, last: 1, step: 1, single_key: true },
        "LPUSHX" => { first: 1, last: 1, step: 1, single_key: true },
        "LRANGE" => { first: 1, last: 1, step: 1, single_key: true },
        "LREM" => { first: 1, last: 1, step: 1, single_key: true },
        "LSET" => { first: 1, last: 1, step: 1, single_key: true },
        "LTRIM" => { first: 1, last: 1, step: 1, single_key: true },
        "MGET" => { first: 1, last: -1, step: 1, single_key: false },
        "MIGRATE" => { first: 3, last: 3, step: 1, single_key: true },
        "MOVE" => { first: 1, last: 1, step: 1, single_key: true },
        "MSET" => { first: 1, last: -1, step: 2, single_key: false },
        "MSETNX" => { first: 1, last: -1, step: 2, single_key: false },
        "OBJECT" => { first: 2, last: 2, step: 1, single_key: true },
        "PERSIST" => { first: 1, last: 1, step: 1, single_key: true },
        "PEXPIRE" => { first: 1, last: 1, step: 1, single_key: true },
        "PEXPIREAT" => { first: 1, last: 1, step: 1, single_key: true },
        "PFADD" => { first: 1, last: 1, step: 1, single_key: true },
        "PFCOUNT" => { first: 1, last: -1, step: 1, single_key: false },
        "PFDEBUG" => { first: 2, last: 2, step: 1, single_key: true },
        "PFMERGE" => { first: 1, last: -1, step: 1, single_key: false },
        "PSETEX" => { first: 1, last: 1, step: 1, single_key: true },
        "PTTL" => { first: 1, last: 1, step: 1, single_key: true },
        "RENAME" => { first: 1, last: 2, step: 1, single_key: false },
        "RENAMENX" => { first: 1, last: 2, step: 1, single_key: false },
        "RESTORE" => { first: 1, last: 1, step: 1, single_key: true },
        "RESTORE-ASKING" => { first: 1, last: 1, step: 1, single_key: true },
        "RPOP" => { first: 1, last: 1, step: 1, single_key: true },
        "RPOPLPUSH" => { first: 1, last: 2, step: 1, single_key: false },
        "RPUSH" => { first: 1, last: 1, step: 1, single_key: true },
        "RPUSHX" => { first: 1, last: 1, step: 1, single_key: true },
        "SADD" => { first: 1, last: 1, step: 1, single_key: true },
        "SCARD" => { first: 1, last: 1, step: 1, single_key: true },
        "SDIFF" => { first: 1, last: -1, step: 1, single_key: false },
        "SDIFFSTORE" => { first: 1, last: -1, step: 1, single_key: false },
        "SET" => { first: 1, last: 1, step: 1, single_key: true },
        "SETBIT" => { first: 1, last: 1, step: 1, single_key: true },
        "SETEX" => { first: 1, last: 1, step: 1, single_key: true },
        "SETNX" => { first: 1, last: 1, step: 1, single_key: true },
        "SETRANGE" => { first: 1, last: 1, step: 1, single_key: true },
        "SINTER" => { first: 1, last: -1, step: 1, single_key: false },
        "SINTERSTORE" => { first: 1, last: -1, step: 1, single_key: false },
        "SISMEMBER" => { first: 1, last: 1, step: 1, single_key: true },
        "SMEMBERS" => { first: 1, last: 1, step: 1, single_key: true },
        "SMISMEMBER" => { first: 1, last: 1, step: 1, single_key: true },
        "SMOVE" => { first: 1, last: 2, step: 1, single_key: false },
        "SORT" => { first: 1, last: 1, step: 1, single_key: true },
        "SPOP" => { first: 1, last: 1, step: 1, single_key: true },
        "SRANDMEMBER" => { first: 1, last: 1, step: 1, single_key: true },
        "SREM" => { first: 1, last: 1, step: 1, single_key: true },
        "SSCAN" => { first: 1, last: 1, step: 1, single_key: true },
        "STRLEN" => { first: 1, last: 1, step: 1, single_key: true },
        "SUBSTR" => { first: 1, last: 1, step: 1, single_key: true },
        "SUNION" => { first: 1, last: -1, step: 1, single_key: false },
        "SUNIONSTORE" => { first: 1, last: -1, step: 1, single_key: false },
        "TOUCH" => { first: 1, last: -1, step: 1, single_key: false },
        "TTL" => { first: 1, last: 1, step: 1, single_key: true },
        "TYPE" => { first: 1, last: 1, step: 1, single_key: true },
        "UNLINK" => { first: 1, last: -1, step: 1, single_key: false },
        "WATCH" => { first: 1, last: -1, step: 1, single_key: false },
        "XACK" => { first: 1, last: 1, step: 1, single_key: true },
        "XADD" => { first: 1, last: 1, step: 1, single_key: true },
        "XAUTOCLAIM" => { first: 1, last: 1, step: 1, single_key: true },
        "XCLAIM" => { first: 1, last: 1, step: 1, single_key: true },
        "XDEL" => { first: 1, last: 1, step: 1, single_key: true },
        "XGROUP" => { first: 2, last: 2, step: 1, single_key: true },
        "XINFO" => { first: 2, last: 2, step: 1, single_key: true },
        "XLEN" => { first: 1, last: 1, step: 1, single_key: true },
        "XPENDING" => { first: 1, last: 1, step: 1, single_key: true },
        "XRANGE" => { first: 1, last: 1, step: 1, single_key: true },
        "XREVRANGE" => { first: 1, last: 1, step: 1, single_key: true },
        "XSETID" => { first: 1, last: 1, step: 1, single_key: true },
        "XTRIM" => { first: 1, last: 1, step: 1, single_key: true },
        "ZADD" => { first: 1, last: 1, step: 1, single_key: true },
        "ZCARD" => { first: 1, last: 1, step: 1, single_key: true },
        "ZCOUNT" => { first: 1, last: 1, step: 1, single_key: true },
        "ZDIFFSTORE" => { first: 1, last: 1, step: 1, single_key: true },
        "ZINCRBY" => { first: 1, last: 1, step: 1, single_key: true },
        "ZINTERSTORE" => { first: 1, last: 1, step: 1, single_key: true },
        "ZLEXCOUNT" => { first: 1, last: 1, step: 1, single_key: true },
        "ZMSCORE" => { first: 1, last: 1, step: 1, single_key: true },
        "ZPOPMAX" => { first: 1, last: 1, step: 1, single_key: true },
        "ZPOPMIN" => { first: 1, last: 1, step: 1, single_key: true },
        "ZRANDMEMBER" => { first: 1, last: 1, step: 1, single_key: true },
        "ZRANGE" => { first: 1, last: 1, step: 1, single_key: true },
        "ZRANGEBYLEX" => { first: 1, last: 1, step: 1, single_key: true },
        "ZRANGEBYSCORE" => { first: 1, last: 1, step: 1, single_key: true },
        "ZRANGESTORE" => { first: 1, last: 2, step: 1, single_key: false },
        "ZRANK" => { first: 1, last: 1, step: 1, single_key: true },
        "ZREM" => { first: 1, last: 1, step: 1, single_key: true },
        "ZREMRANGEBYLEX" => { first: 1, last: 1, step: 1, single_key: true },
        "ZREMRANGEBYRANK" => { first: 1, last: 1, step: 1, single_key: true },
        "ZREMRANGEBYSCORE" => { first: 1, last: 1, step: 1, single_key: true },
        "ZREVRANGE" => { first: 1, last: 1, step: 1, single_key: true },
        "ZREVRANGEBYLEX" => { first: 1, last: 1, step: 1, single_key: true },
        "ZREVRANGEBYSCORE" => { first: 1, last: 1, step: 1, single_key: true },
        "ZREVRANK" => { first: 1, last: 1, step: 1, single_key: true },
        "ZSCAN" => { first: 1, last: 1, step: 1, single_key: true },
        "ZSCORE" => { first: 1, last: 1, step: 1, single_key: true },
        "ZUNIONSTORE" => { first: 1, last: 1, step: 1, single_key: true }
      }.freeze

      CrossSlotError = Class.new(StandardError)

      class << self
        def validate(commands)
          return if commands.empty?

          # early exit for single-command (non-pipelined) if it is a single-key-command
          command_name = commands.size > 1 ? "PIPELINE/MULTI" : commands.first.first.to_s.upcase
          return if commands.size == 1 && REDIS_COMMANDS.dig(command_name, :single_key)

          keys = commands.map { |command| extract_keys(command) }.flatten

          {
            valid: !has_cross_slot_keys?(keys),
            command_name: command_name,
            key_count: keys.size,
            allowed: allow_cross_slot_commands?
          }
        end

        # Keep track of the call stack to allow nested calls to work.
        def allow_cross_slot_commands
          Thread.current[:allow_cross_slot_commands] ||= 0
          Thread.current[:allow_cross_slot_commands] += 1

          yield
        ensure
          Thread.current[:allow_cross_slot_commands] -= 1
        end

        def allow_cross_slot_commands?
          Thread.current[:allow_cross_slot_commands].to_i > 0
        end

        private

        def extract_keys(command)
          argument_positions = REDIS_COMMANDS[command.first.to_s.upcase]

          return [] unless argument_positions

          arguments = command.flatten[argument_positions[:first]..argument_positions[:last]]
          arguments.each_slice(argument_positions[:step]).map(&:first)
        end

        def has_cross_slot_keys?(keys)
          keys.map { |key| key_slot(key) }.uniq.many? # rubocop: disable CodeReuse/ActiveRecord
        end

        def key_slot(key)
          ::RedisClient::Cluster::KeySlotConverter.convert(extract_hash_tag(key))
        end

        # This is almost identical to Redis::Cluster::Command#extract_hash_tag,
        # except that it returns the original string if no hash tag is found.
        #
        def extract_hash_tag(key)
          s = key.index('{')

          return key unless s

          e = key.index('}', s + 1)

          return key unless e

          key[s + 1..e - 1]
        end
      end
    end
  end
end
