# frozen_string_literal: true

require 'redis'

module SystemCheck
  module App
    class RedisVersionCheck < SystemCheck::BaseCheck
      MIN_REDIS_VERSION = '6.0.0'
      RECOMMENDED_REDIS_VERSION = "6.2.14"
      set_name "Redis version >= #{RECOMMENDED_REDIS_VERSION}?"

      @custom_error_message = ''

      def check?
        redis_version = Gitlab::Redis::Queues.with do |redis|
          redis.info['redis_version']
        end

        status = true

        if !redis_version
          @custom_error_message = "Could not retrieve the Redis version. Please check if your settings are correct"
          status = false
        elsif Gem::Version.new(redis_version) < Gem::Version.new(MIN_REDIS_VERSION)
          @custom_error_message = "Your Redis version #{redis_version} is not supported anymore. Update your Redis server to a version >= #{RECOMMENDED_REDIS_VERSION}"
          status = false
        elsif Gem::Version.new(redis_version) < Gem::Version.new(RECOMMENDED_REDIS_VERSION)
          @custom_error_message = "Your Redis version #{redis_version} has reached end-of-life (EOL). Update your Redis server to a version >= #{RECOMMENDED_REDIS_VERSION}"
          status = false
        end

        status
      end

      def show_error
        try_fixing_it(
          @custom_error_message
        )
        for_more_information(
          'doc/administration/redis/index.html#redis-replication-and-failover-using-the-non-bundled-redis'
        )
        fix_and_rerun
      end
    end
  end
end
