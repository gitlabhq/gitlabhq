# frozen_string_literal: true

require 'yaml'
require 'json'
require_relative 'redis/queues' unless defined?(Gitlab::Redis::Queues)

# This service is run independently of the main Rails process,
# therefore the `Rails` class and its methods are unavailable.

module Gitlab
  module MailRoom
    RAILS_ROOT_DIR = Pathname.new('../..').expand_path(__dir__).freeze

    DEFAULT_CONFIG = {
      enabled: false,
      port: 143,
      ssl: false,
      start_tls: false,
      mailbox: 'inbox',
      idle_timeout: 60,
      log_path: RAILS_ROOT_DIR.join('log', 'mail_room_json.log')
    }.freeze

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

        config = load_from_yaml || {}
        config = DEFAULT_CONFIG.merge(config) do |_key, oldval, newval|
          newval.nil? ? oldval : newval
        end

        if config[:enabled] && config[:address]
          gitlab_redis_queues = Gitlab::Redis::Queues.new(rails_env)
          config[:redis_url] = gitlab_redis_queues.url

          if gitlab_redis_queues.sentinels?
            config[:sentinels] = gitlab_redis_queues.sentinels
          end
        end

        config[:log_path] = File.expand_path(config[:log_path], RAILS_ROOT_DIR)
        config
      end

      def rails_env
        @rails_env ||= ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
      end

      def config_file
        ENV['MAIL_ROOM_GITLAB_CONFIG_FILE'] || File.expand_path('../../config/gitlab.yml', __dir__)
      end

      def load_from_yaml
        YAML.load_file(config_file)[rails_env].deep_symbolize_keys[:incoming_email]
      end
    end
  end
end
