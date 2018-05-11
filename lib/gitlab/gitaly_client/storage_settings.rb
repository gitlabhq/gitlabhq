module Gitlab
  module GitalyClient
    # This is a chokepoint that is meant to help us stop remove all places
    # where production code (app, config, db, lib) touches Git repositories
    # directly.
    class StorageSettings
      DirectPathAccessError = Class.new(StandardError)
      InvalidConfigurationError = Class.new(StandardError)

      INVALID_STORAGE_MESSAGE = <<~MSG.freeze
        Storage is invalid because it has no `path` key.

        For source installations, update your config/gitlab.yml Refer to gitlab.yml.example for an updated example.
        If you're using the Gitlab Development Kit, you can update your configuration running `gdk reconfigure`.
      MSG

      # This class will give easily recognizable NoMethodErrors
      Deprecated = Class.new

      attr_reader :legacy_disk_path

      def initialize(storage)
        raise InvalidConfigurationError, "expected a Hash, got a #{storage.class.name}" unless storage.is_a?(Hash)
        raise InvalidConfigurationError, INVALID_STORAGE_MESSAGE unless storage.has_key?('path')

        # Support a nil 'path' field because some of the circuit breaker tests use it.
        @legacy_disk_path = File.expand_path(storage['path'], Rails.root) if storage['path']

        storage['path'] = Deprecated
        @hash = storage
      end

      def gitaly_address
        @hash.fetch(:gitaly_address)
      end

      private

      def method_missing(m, *args, &block)
        @hash.public_send(m, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end
end
