# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      class Cookie
        SCHEMA = {
          'jid' => String,
          'offsets' => Hash,
          'wal_locations' => Hash,
          'existing_wal_locations' => Hash
        }.freeze

        # Maps values inside the cookie to respective proc
        CONVERTER = {
          # Lua (specifically lua-cmsgpack in Redis) converts empty hash into empty array.
          # We validate the cookie from duplicate job middleware to convert empty array back to empty hash.
          Array => ->(val) { val.empty? ? {} : val }
        }.freeze

        # Generally speaking, updating a Redis key by deserializing and
        # serializing it on the Redis server is bad for performance. However in
        # the case of DuplicateJobs we know that key updates are rare, and the
        # most common operations are setting, getting and deleting the key. The
        # aim of this design is to make the common operations as fast as
        # possible.
        UPDATE_WAL_COOKIE_SCRIPT = <<~LUA
          local cookie_msgpack = redis.call("get", KEYS[1])
          if not cookie_msgpack then
            return
          end
          local cookie = cmsgpack.unpack(cookie_msgpack)

          for i = 1, #ARGV, 3 do
            local connection = ARGV[i]
            local current_offset = cookie.offsets[connection]
            local new_offset = tonumber(ARGV[i+1])
            if not current_offset or (new_offset and current_offset < new_offset) then
              cookie.offsets[connection] = new_offset
              cookie.wal_locations[connection] = ARGV[i+2]
            end
          end

          redis.call("set", KEYS[1], cmsgpack.pack(cookie), "keepttl")
        LUA

        def self.read(key)
          cookie = with_redis { |r| MessagePack.unpack(r.get(key) || "\x80") }
          validate!(cookie)
        end

        def self.delete!(key)
          with_redis { |redis| redis.del(key) }
        end

        def self.update_wal_locations!(key, argv)
          with_redis { |r| r.eval(UPDATE_WAL_COOKIE_SCRIPT, keys: [key], argv: argv) }
        end

        def self.with_redis(&)
          Gitlab::Redis::QueuesMetadata.with(&) # rubocop:disable CodeReuse/ActiveRecord -- not an ActiveRecord model
        end

        private_class_method def self.validate!(cookie)
          convert_values!(cookie)

          cookie
        end

        private_class_method def self.convert_values!(cookie)
          cookie.each do |key, val|
            next unless needs_conversion?(key, val)

            cookie[key] = CONVERTER[val.class].call(val)
          end
        end

        private_class_method def self.needs_conversion?(key, val)
          expected_type = SCHEMA[key]
          return false unless expected_type

          !val.is_a?(expected_type) && CONVERTER.key?(val.class)
        end

        attr_accessor :cookie

        def initialize(jid:, existing_wal_locations:)
          @cookie = {
            'jid' => jid,
            'existing_wal_locations' => existing_wal_locations,
            'offsets' => {},
            'wal_locations' => {}
          }
        end

        def write(key, expiry)
          self.class.with_redis { |r| r.set(key, cookie.to_msgpack, nx: true, ex: expiry) }
        end
      end
    end
  end
end
