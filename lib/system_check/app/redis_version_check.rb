# frozen_string_literal: true

module SystemCheck
  module App
    class RedisVersionCheck < SystemCheck::BaseCheck
      MIN_REDIS_VERSION = '2.8.0'
      set_name "Redis version >= #{MIN_REDIS_VERSION}?"

      def check?
        redis_version = run_command(%w(redis-cli --version))
        redis_version = redis_version.try(:match, /redis-cli (\d+\.\d+\.\d+)/)

        redis_version && (Gem::Version.new(redis_version[1]) > Gem::Version.new(MIN_REDIS_VERSION))
      end

      def show_error
        try_fixing_it(
          "Update your redis server to a version >= #{MIN_REDIS_VERSION}"
        )
        for_more_information(
          'gitlab-public-wiki/wiki/Trouble-Shooting-Guide in section sidekiq'
        )
        fix_and_rerun
      end
    end
  end
end
