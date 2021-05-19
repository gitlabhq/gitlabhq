# frozen_string_literal: true

require 'rails'
require 'redis'

module Gitlab
  module Instrumentation
    module RedisClusterValidator
      # Generate with:
      #
      # Gitlab::Redis::Cache
      #   .with { |redis| redis.call('COMMAND') }
      #   .select { |command| command[3] != command[4] }
      #   .map { |command| [command[0].upcase, { first: command[3], last: command[4], step: command[5] }] }
      #   .sort_by(&:first)
      #   .to_h
      #
      MULTI_KEY_COMMANDS = {
        "BITOP" => { first: 2, last: -1, step: 1 },
        "BLPOP" => { first: 1, last: -2, step: 1 },
        "BRPOP" => { first: 1, last: -2, step: 1 },
        "BRPOPLPUSH" => { first: 1, last: 2, step: 1 },
        "BZPOPMAX" => { first: 1, last: -2, step: 1 },
        "BZPOPMIN" => { first: 1, last: -2, step: 1 },
        "DEL" => { first: 1, last: -1, step: 1 },
        "EXISTS" => { first: 1, last: -1, step: 1 },
        "MGET" => { first: 1, last: -1, step: 1 },
        "MSET" => { first: 1, last: -1, step: 2 },
        "MSETNX" => { first: 1, last: -1, step: 2 },
        "PFCOUNT" => { first: 1, last: -1, step: 1 },
        "PFMERGE" => { first: 1, last: -1, step: 1 },
        "RENAME" => { first: 1, last: 2, step: 1 },
        "RENAMENX" => { first: 1, last: 2, step: 1 },
        "RPOPLPUSH" => { first: 1, last: 2, step: 1 },
        "SDIFF" => { first: 1, last: -1, step: 1 },
        "SDIFFSTORE" => { first: 1, last: -1, step: 1 },
        "SINTER" => { first: 1, last: -1, step: 1 },
        "SINTERSTORE" => { first: 1, last: -1, step: 1 },
        "SMOVE" => { first: 1, last: 2, step: 1 },
        "SUNION" => { first: 1, last: -1, step: 1 },
        "SUNIONSTORE" => { first: 1, last: -1, step: 1 },
        "UNLINK" => { first: 1, last: -1, step: 1 },
        "WATCH" => { first: 1, last: -1, step: 1 }
      }.freeze

      CrossSlotError = Class.new(StandardError)

      class << self
        def validate!(command)
          return unless Rails.env.development? || Rails.env.test?
          return if allow_cross_slot_commands?

          command_name = command.first.to_s.upcase
          argument_positions = MULTI_KEY_COMMANDS[command_name]

          return unless argument_positions

          arguments = command.flatten[argument_positions[:first]..argument_positions[:last]]

          key_slots = arguments.each_slice(argument_positions[:step]).map do |args|
            key_slot(args.first)
          end

          if key_slots.uniq.many? # rubocop: disable CodeReuse/ActiveRecord
            raise CrossSlotError, "Redis command #{command_name} arguments hash to different slots. See https://docs.gitlab.com/ee/development/redis.html#multi-key-commands"
          end
        end

        # Keep track of the call stack to allow nested calls to work.
        def allow_cross_slot_commands
          Thread.current[:allow_cross_slot_commands] ||= 0
          Thread.current[:allow_cross_slot_commands] += 1

          yield
        ensure
          Thread.current[:allow_cross_slot_commands] -= 1
        end

        private

        def allow_cross_slot_commands?
          Thread.current[:allow_cross_slot_commands].to_i > 0
        end

        def key_slot(key)
          ::Redis::Cluster::KeySlotConverter.convert(extract_hash_tag(key))
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
