# frozen_string_literal: true

if Gem::Version.new(RedisClient::VERSION) != Gem::Version.new('0.20.0')
  raise 'New version of redis-client detected, please remove or update this patch'
end

module Gitlab
  module Patch
    module RedisClientSentinelConfig
      # we manually apply the fix in
      # https://github.com/redis-rb/redis-client/commit/26d355441f5b455294de887397ed8bea2e2c7275
      # until a new tag is released
      def each_sentinel
        last_error = nil
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- Directly references code in redis-client gem
        @sentinel_configs.dup.each do |sentinel_config|
          sentinel_client = sentinel_client(sentinel_config)
          success = true
          begin
            yield sentinel_client
          rescue RedisClient::Error => error
            last_error = error
            success = false
            sleep SENTINEL_DELAY
          ensure
            @sentinel_configs.unshift(@sentinel_configs.delete(sentinel_config)) if success
            # Redis Sentinels may be configured to have a lower maxclients setting than
            # the Redis nodes. Close the connection to the Sentinel node to avoid using
            # a connection.
            sentinel_client.close
            # rubocop:enable Gitlab/ModuleWithInstanceVariables
          end
        end
      end
    end
  end
end
