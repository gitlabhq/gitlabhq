# frozen_string_literal: true

require 'yaml'
require 'json'
require 'pathname'
require 'active_support'
require "active_support/core_ext/module/delegation"
require_relative 'encrypted_configuration' unless defined?(Gitlab::EncryptedConfiguration)
require_relative 'redis/config_generator' unless defined?(Gitlab::Redis::ConfigGenerator)
require_relative 'redis/queues' unless defined?(Gitlab::Redis::Queues)

# This service is run independently of the main Rails process,
# therefore the `Rails` class and its methods are unavailable.

module Gitlab
  module MailRoom
    RAILS_ROOT_DIR = Pathname.new('../..').expand_path(__dir__).freeze

    DELIVERY_METHOD_SIDEKIQ = 'sidekiq'
    DELIVERY_METHOD_WEBHOOK = 'webhook'
    INTERNAL_API_REQUEST_HEADER = 'Gitlab-Mailroom-Api-Request'
    INTERNAL_API_REQUEST_JWT_ISSUER = 'gitlab-mailroom'

    DEFAULT_CONFIG = {
      enabled: false,
      port: 143,
      ssl: false,
      start_tls: false,
      mailbox: 'inbox',
      idle_timeout: 60,
      log_path: RAILS_ROOT_DIR.join('log', 'mail_room_json.log'),
      expunge_deleted: false,
      delivery_method: DELIVERY_METHOD_SIDEKIQ
    }.freeze

    # Email specific configuration which is merged with configuration
    # fetched from YML config file.
    MAILBOX_SPECIFIC_CONFIGS = {
      incoming_email: {
        queue: 'default',
        worker: 'EmailReceiverWorker'
      },
      service_desk_email: {
        queue: 'default',
        worker: 'ServiceDeskEmailReceiverWorker'
      }
    }.freeze

    # Default path strings (this is a data duplication
    # with Settings which is not pulled in - see the service
    # comment at the top of this file)
    DEFAULT_PATHS = {
      shared_path: 'shared',
      encrypted_settings_path: 'encrypted_settings',
      incoming_email: {
        encrypted_secret_filename: 'incoming_email.yaml.enc'
      },
      service_desk_email: {
        encrypted_secret_filename: 'service_desk_email.yaml.enc'
      }
    }.freeze

    class << self
      def enabled_configs
        @enabled_configs ||= configs.select { |_key, config| enabled?(config) }
      end

      def enabled_mailbox_types
        enabled_configs.keys.map(&:to_s)
      end

      def worker_for(mailbox_type)
        MAILBOX_SPECIFIC_CONFIGS.try(:[], mailbox_type.to_sym).try(:[], :worker).try(:safe_constantize)
      end

      private

      def enabled?(config)
        config[:enabled] && !config[:address].to_s.empty?
      end

      def configs
        MAILBOX_SPECIFIC_CONFIGS.to_h { |key, _value| [key, fetch_config(key)] }
      end

      def fetch_config(config_key)
        return {} unless File.exist?(config_file)

        config = merged_configs(config_key)

        config.merge!(redis_config) if enabled?(config)

        config[:log_path] = File.expand_path(config[:log_path], RAILS_ROOT_DIR)

        # override password/user from any encrypted secrets
        if secrets = decrypted_secrets(config_key)
          config[:password] = secrets[:password] if secrets[:password]
          config[:user] = secrets[:user] if secrets[:user]
        end

        config
      end

      def merged_configs(config_key)
        yml_config = load_yaml.fetch(config_key, {})
        specific_config = MAILBOX_SPECIFIC_CONFIGS.fetch(config_key, {})
        DEFAULT_CONFIG.merge(specific_config, yml_config) do |_key, oldval, newval|
          newval.nil? ? oldval : newval
        end
      end

      def redis_config
        gitlab_redis_queues = Gitlab::Redis::Queues.new(rails_env)

        config = { redis_url: gitlab_redis_queues.url, redis_db: gitlab_redis_queues.db }

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
        @yaml ||= YAML.safe_load_file(config_file, aliases: true)[rails_env].deep_symbolize_keys
      end

      def application_secrets_file
        ENV['MAIL_ROOM_GITLAB_SECRETS_FILE'] || File.expand_path('../../config/secrets.yml', __dir__)
      end

      def application_secrets
        @application_secrets ||= {}.tap do |application_secrets|
          # Uses Rails::Secret.parse
          # from: https://github.com/rails/rails/blob/v6.1.6.1/railties/lib/rails/secrets.rb#L24
          erb_processed_yaml = ERB.new(File.read(application_secrets_file)).result
          yaml_secrets =
            YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(erb_processed_yaml) : YAML.safe_load(erb_processed_yaml)
          application_secrets.merge!(yaml_secrets["shared"].deep_symbolize_keys) if yaml_secrets["shared"]
          application_secrets.merge!(yaml_secrets[rails_env].deep_symbolize_keys) if yaml_secrets[rails_env]
        end
      end

      def default_encrypted_secret_filename(config_key)
        DEFAULT_PATHS[config_key][:encrypted_secret_filename]
      end

      def encrypted_secret_file(config_key)
        config = merged_configs(config_key)
        return config[:encrypted_secret_file] if config[:encrypted_secret_file]

        config_yaml = load_yaml
        # Path handling for shared.path / encrypted_settings.path is a duplicate
        # of the logic in config/initializers/1_settings.rb
        shared_path = File.expand_path(config_yaml.dig(:shared, :path) ||
                                       DEFAULT_PATHS[:shared_path], RAILS_ROOT_DIR)
        encrypted_settings_path =
          File.expand_path(config_yaml.dig(:encrypted_settings, :path) ||
                           File.join(shared_path, DEFAULT_PATHS[:encrypted_settings_path]),
            RAILS_ROOT_DIR)
        File.join(encrypted_settings_path, default_encrypted_secret_filename(config_key))
      end

      def encrypted_configuration_settings(config_key)
        {
          content_path: encrypted_secret_file(config_key),
          base_key: application_secrets[:encrypted_settings_key_base],
          previous_keys: application_secrets[:rotated_encrypted_settings_key_base] || []
        }
      end

      def decrypted_secrets(config_key)
        settings = encrypted_configuration_settings(config_key)
        return if settings[:base_key].nil?

        encrypted = Gitlab::EncryptedConfiguration.new(**settings)
        encrypted.active? ? encrypted.config : nil
      end
    end
  end
end
