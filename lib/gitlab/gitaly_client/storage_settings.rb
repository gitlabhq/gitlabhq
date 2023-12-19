# frozen_string_literal: true

module Gitlab
  module GitalyClient
    # This is a chokepoint that is meant to help us stop remove all places
    # where production code (app, config, db, lib) touches Git repositories
    # directly.
    class StorageSettings
      extend Gitlab::TemporarilyAllow

      DirectPathAccessError = Class.new(StandardError)
      InvalidConfigurationError = Class.new(StandardError)

      INVALID_STORAGE_MESSAGE = <<~MSG
        Storage is invalid because it has no `gitaly_address` key.

        For source installations, update your config/gitlab.yml Refer to gitlab.yml.example for an updated example.
        If you're using the GitLab Development Kit, you can update your configuration running `gdk reconfigure`.
      MSG

      # This class will give easily recognizable NoMethodErrors
      Deprecated = Class.new

      MUTEX = Mutex.new

      ALLOW_KEY = :allow_disk_access

      # If your code needs this method then your code needs to be fixed.
      def self.allow_disk_access
        temporarily_allow(ALLOW_KEY) { yield }
      end

      def self.disk_access_denied?
        !temporarily_allowed?(ALLOW_KEY)
      rescue StandardError
        false # Err on the side of caution, don't break gitlab for people
      end

      def initialize(storage)
        raise InvalidConfigurationError, "expected a Hash, got a #{storage.class.name}" unless storage.is_a?(Hash)

        @hash = ActiveSupport::HashWithIndifferentAccess.new(storage)

        raise InvalidConfigurationError, INVALID_STORAGE_MESSAGE unless @hash.has_key?('gitaly_address')

        # Support a nil 'path' field because some of the circuit breaker tests use it.
        @legacy_disk_path = File.expand_path(@hash['path'], Rails.root) if @hash['path'] && @hash['path'] != Deprecated

        @hash['path'] = Deprecated
      end

      def gitaly_address
        @hash.fetch(:gitaly_address)
      end

      def legacy_disk_path
        # Do not use self.class due to Spring reloading issues
        if Gitlab::GitalyClient::StorageSettings.disk_access_denied?
          raise DirectPathAccessError, "git disk access denied"
        end

        @legacy_disk_path
      end

      private

      def method_missing(msg, *args, &block)
        @hash.public_send(msg, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end
end
