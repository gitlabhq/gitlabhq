# frozen_string_literal: true

module Gitlab
  # Reads operator-provided instance settings from a config file mounted by the distribution
  # (for example, Helm), enforces their values, and locks them against changes from the Admin
  # UI and REST API. Only settings that map to real {ApplicationSetting} columns are honored.
  #
  # The file has two root keys: `installation` (metadata such as `managed_by`) and
  # `managed_settings` (the enforced `column => value` pairs).
  #
  # @see ApplicationSettings::UpdateService for write rejection.
  module ManagedSettings
    # Raised at boot when the managed settings file cannot be parsed, validated, or applied.
    InvalidConfigurationError = Class.new(StandardError)

    # Path to the operator-provided config file.
    PATH = Rails.root.join('config/managed_settings.yml')

    # Allowlist of {ApplicationSetting} columns the distribution is allowed to manage.
    SUPPORTED_SETTINGS = %i[
      sidekiq_timezone_override
    ].to_set.freeze

    class << self
      # Whether managed settings must be enforced: the config file is present.
      #
      # @return [Boolean]
      def enabled?
        file_present?
      end

      # Name of the party managing the installation (for example, "Helm Charts" or
      # "GitLab Dedicated"), or nil when the file does not declare one.
      #
      # @raise [InvalidConfigurationError] when the config file cannot be parsed
      # @return [String, nil]
      def managed_by
        installation[:managed_by]
      end

      # Recognized managed settings as a `column => value` hash. Keys that do not map to an
      # {ApplicationSetting} column are dropped with a logged warning. Memoized.
      #
      # @raise [InvalidConfigurationError] when the config file cannot be parsed
      # @return [Hash{Symbol => Object}]
      def all
        return {} unless enabled?

        @all ||= recognized_settings
      end

      # Names of the managed columns.
      #
      # @raise [InvalidConfigurationError] when the config file cannot be parsed
      # @return [Array<Symbol>]
      def keys
        all.keys
      end

      # Whether the given attribute is managed.
      #
      # @param attr [Symbol, String]
      # @raise [InvalidConfigurationError] when the config file cannot be parsed
      # @return [Boolean]
      def managed?(attr)
        all.key?(attr.to_sym)
      end

      # Enforced value for a managed attribute.
      #
      # @param attr [Symbol, String]
      # @raise [InvalidConfigurationError] when the config file cannot be parsed
      # @return [Object, nil]
      def [](attr)
        all[attr.to_sym]
      end

      # Validates that every recognized managed setting holds a valid value, so a misconfigured
      # file prevents the application from booting. Unknown keys are ignored (see {#all}).
      #
      # @raise [InvalidConfigurationError] when a recognized column has an invalid value
      # @return [void]
      def validate!
        return if all.empty?

        candidate = ::Gitlab::CurrentSettings.current_application_settings.dup
        candidate.assign_attributes(all)
        candidate.valid?

        invalid = all.keys.each_with_object({}) do |attr, memo|
          messages = candidate.errors.messages_for(attr)
          memo[attr] = messages if messages.any?
        end

        return if invalid.empty?

        details = invalid.map { |attr, messages| "#{attr}: #{messages.join(', ')}" }.join('; ')
        raise InvalidConfigurationError, "Invalid managed settings: #{details}"
      end

      # Persists the managed values onto the application settings record so the enforced values
      # are stored in the database. Validates first, so an invalid value prevents boot. No-op
      # when disabled or when the database is not ready (migrations, asset compilation).
      #
      # @raise [InvalidConfigurationError] when a recognized column has an invalid value
      # @return [void]
      def apply!
        return unless enabled?
        return unless database_ready?

        validate!

        settings = ::Gitlab::CurrentSettings.current_application_settings
        changes = all.select { |attr, value| settings.read_attribute(attr) != value }
        return if changes.empty?

        settings.update!(changes)
      rescue ActiveRecord::RecordInvalid => e
        # Surface cross-field validation failures as a configuration error so boot fails clearly.
        raise InvalidConfigurationError, "Failed to apply managed settings: #{e.message}"
      end

      # Clears memoized state.
      #
      # @return [void]
      def reset!
        @all = nil
        @raw = nil
        @file_present = nil
      end

      private

      def recognized_settings
        configured = raw.fetch(:managed_settings, {})
        known = configured.select { |key, _| allowed_keys.include?(key) }
        unknown = configured.except(*known.keys)

        unknown.each_key do |key|
          Gitlab::AppLogger.warn(message: 'Ignoring unknown or unsupported managed setting', setting: key.to_s)
        end

        known
      end

      def installation
        raw.fetch(:installation, {})
      end

      def allowed_keys
        SUPPORTED_SETTINGS
      end

      def raw
        @raw ||= file_present? ? load_file : {}
      end

      def load_file
        (YAML.safe_load_file(PATH) || {}).deep_symbolize_keys
      rescue Psych::Exception => e
        # Fail closed: a malformed file must not silently disable enforcement.
        raise InvalidConfigurationError, "Failed to parse managed settings file: #{e.message}"
      end

      def file_present?
        return @file_present unless @file_present.nil?

        @file_present = File.exist?(PATH)
      end

      def database_ready?
        ::ApplicationSetting.connection.active? &&
          ::ApplicationSetting.database.cached_table_exists? &&
          !::ApplicationSetting.connection_pool.migration_context.needs_migration?
      rescue ActiveRecord::ActiveRecordError, PG::Error
        false
      end
    end
  end
end
