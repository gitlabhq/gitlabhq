# frozen_string_literal: true

require 'yaml'
require 'json'
require 'pathname'
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
      log_path: RAILS_ROOT_DIR.join('log', 'mail_room_json.log'),
      expunge_deleted: false
    }.freeze

    # Email specific configuration which is merged with configuration
    # fetched from YML config file.
    ADDRESS_SPECIFIC_CONFIG = {
      incoming_email: {
        queue: 'email_receiver',
        worker: 'EmailReceiverWorker'
      },
      service_desk_email: {
        queue: 'service_desk_email_receiver',
        worker: 'ServiceDeskEmailReceiverWorker'
      }
    }.freeze

    class << self
      def enabled_configs
        @enabled_configs ||= configs.select { |config| enabled?(config) }
      end

      private

      def enabled?(config)
        config[:enabled] && !config[:address].to_s.empty?
      end

      def configs
        ADDRESS_SPECIFIC_CONFIG.keys.map { |key| fetch_config(key) }
      end

      def fetch_config(config_key)
        return {} unless File.exist?(config_file)

        config = merged_configs(config_key)
        config.merge!(redis_config) if enabled?(config)
        config[:log_path] = File.expand_path(config[:log_path], RAILS_ROOT_DIR)

        config
      end

      def merged_configs(config_key)
        yml_config = load_yaml.fetch(config_key, {})
        specific_config = ADDRESS_SPECIFIC_CONFIG.fetch(config_key, {})
        DEFAULT_CONFIG.merge(specific_config, yml_config) do |_key, oldval, newval|
          newval.nil? ? oldval : newval
        end
      end

      def redis_config
        gitlab_redis_queues = Gitlab::Redis::Queues.new(rails_env)
        config = { redis_url: gitlab_redis_queues.url }

        if gitlab_redis_queues.sentinels?
          config[:sentinels] = gitlab_redis_queues.sentinels
        end

        config
      end

      def rails_env
        @rails_env ||= ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
      end

      def config_file
        ENV['MAIL_ROOM_GITLAB_CONFIG_FILE'] || File.expand_path('../../config/gitlab.yml', __dir__)
      end

      def load_yaml
        @yaml ||= YAML.load_file(config_file)[rails_env].deep_symbolize_keys
      end
    end
  end
end
