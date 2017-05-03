require 'yaml'
require 'json'
require_relative 'redis' unless defined?(Gitlab::Redis)

module Gitlab
  module MailRoom
    class << self
      def enabled?
        config[:enabled] && config[:address]
      end

      def config
        @config ||= fetch_config
      end

      def reset_config!
        @config = nil
      end

      private

      def fetch_config
        return {} unless File.exist?(config_file)

        rails_env = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
        all_config = YAML.load_file(config_file)[rails_env].deep_symbolize_keys

        config = all_config[:incoming_email] || {}
        config[:enabled] = false if config[:enabled].nil?
        config[:port] = 143 if config[:port].nil?
        config[:ssl] = false if config[:ssl].nil?
        config[:start_tls] = false if config[:start_tls].nil?
        config[:mailbox] = 'inbox' if config[:mailbox].nil?
        config[:idle_timeout] = 60 if config[:idle_timeout].nil?

        if config[:enabled] && config[:address]
          gitlab_redis = Gitlab::Redis.new(rails_env)
          config[:redis_url] = gitlab_redis.url

          if gitlab_redis.sentinels?
            config[:sentinels] = gitlab_redis.sentinels
          end
        end

        config
      end

      def config_file
        ENV['MAIL_ROOM_GITLAB_CONFIG_FILE'] || File.expand_path('../../../config/gitlab.yml', __FILE__)
      end
    end
  end
end
