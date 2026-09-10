# frozen_string_literal: true

module Gitlab
  module Database
    # Reads and validates a table's retention policy declaration.
    #
    # Declarations live in a dedicated file per table:
    #   db/docs/data_retention/<table_name>.yml
    #
    # The fields follow the Data Retention Policy Framework:
    # https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/data_retention_policy_framework/
    class RetentionPolicy
      ALLOWED_FIELDS = %w[
        exclude
        retention_window
        enforcement_strategy
        enforcing
        work_item
        pause_mechanism
      ].freeze

      REQUIRED_FIELDS = %w[
        retention_window
        enforcement_strategy
        enforcing
        pause_mechanism
        work_item
      ].freeze

      EXCLUDE_REASONS = %w[indefinite_retention technical_complexity].freeze
      ENFORCEMENT_STRATEGIES = %w[drop_partition delete_rows transient_data none].freeze
      PAUSE_MECHANISMS = %w[none application_setting feature_flag].freeze

      EXCLUDED_WINDOW = -1
      EXCLUDED_STRATEGY = 'none'

      # Schemas whose tables must declare a retention policy.
      #
      # Enumerated explicitly (rather than derived by exclusion) so that adding a
      # new gitlab_schema triggers a spec failure until it is deliberately listed
      # in ELIGIBLE_SCHEMAS or EXCLUDED_SCHEMAS below. This prevents new schemas
      # from silently bypassing the Data Retention Policy Framework.
      ELIGIBLE_SCHEMAS = %w[
        gitlab_main_org
        gitlab_main_user
        gitlab_main_cell_local
        gitlab_main_cell_setting
        gitlab_sec
        gitlab_internal
        gitlab_shared_org
        gitlab_shared_cell_local
        gitlab_ci
        gitlab_ci_cell_local
        gitlab_pm
        gitlab_sec_cell_local
      ].freeze

      EXCLUDED_SCHEMAS = %w[
        gitlab_geo
        gitlab_main_jh
      ].freeze

      attr_reader :table_name, :data

      def self.eligible_tables
        Gitlab::Database::Dictionary.entries.select do |table|
          ELIGIBLE_SCHEMAS.include?(table.gitlab_schema)
        end
      end

      def self.from_file(path)
        new(File.basename(path, '.yml'), YAML.safe_load_file(path))
      end

      def initialize(table_name, data)
        @table_name = table_name
        @data = data.is_a?(Hash) ? data : {}
      end

      def excluded?
        data['exclude'].present?
      end

      def exclude_reason
        return unless data['exclude'].is_a?(Hash)

        data['exclude']['reason']
      end

      def retention_window
        data['retention_window']
      end

      def enforcement_strategy
        data['enforcement_strategy']
      end

      def pause_mechanism
        return unless data['pause_mechanism'].is_a?(Hash)

        data['pause_mechanism']['type']
      end

      def pause_mechanism_name
        return unless data['pause_mechanism'].is_a?(Hash)

        data['pause_mechanism']['name']
      end

      # Returns an array of human-readable validation errors. Empty means valid.
      def validation_errors
        errors = []
        errors.concat(disallowed_field_errors)
        errors.concat(missing_field_errors)
        errors.concat(exclude_errors)
        errors.concat(enforcement_strategy_errors)
        errors.concat(pause_mechanism_errors)
        errors.concat(coupling_errors)
        errors.concat(type_errors)
        errors
      end

      private

      def disallowed_field_errors
        disallowed = data.keys - ALLOWED_FIELDS
        return [] if disallowed.empty?

        ["fields not allowed: #{disallowed.join(', ')}"]
      end

      def missing_field_errors
        missing = REQUIRED_FIELDS - data.reject { |_, v| v.nil? }.keys
        return [] if missing.empty?

        ["missing required fields: #{missing.join(', ')}"]
      end

      def exclude_errors
        return [] unless excluded?

        return ["exclude.reason must be one of: #{EXCLUDE_REASONS.join(', ')}"] unless
          EXCLUDE_REASONS.include?(exclude_reason)

        []
      end

      def enforcement_strategy_errors
        return [] if enforcement_strategy.nil?
        return [] if ENFORCEMENT_STRATEGIES.include?(enforcement_strategy)

        ["enforcement_strategy must be one of: #{ENFORCEMENT_STRATEGIES.join(', ')}"]
      end

      def pause_mechanism_errors
        raw = data['pause_mechanism']
        return [] if raw.nil?

        return ['pause_mechanism must be a hash with a type and, when type is not none, a name'] unless raw.is_a?(Hash)

        errors = []

        unless PAUSE_MECHANISMS.include?(pause_mechanism)
          errors << "pause_mechanism.type must be one of: #{PAUSE_MECHANISMS.join(', ')}"
        end

        if pause_mechanism != 'none' && pause_mechanism_name.blank?
          errors << "pause_mechanism.name is required when pause_mechanism.type is #{pause_mechanism}"
        end

        errors
      end

      # retention_window must be a positive integer number of days, with -1 reserved
      # as the placeholder for excluded declarations. enforcing must be a boolean.
      def type_errors
        errors = []

        unless valid_retention_window?
          errors << "retention_window must be a positive number of days, or #{EXCLUDED_WINDOW} when excluded"
        end

        enforcing = data['enforcing']
        errors << 'enforcing must be true or false' unless enforcing.nil? || [true, false].include?(enforcing)

        errors
      end

      def valid_retention_window?
        return true if retention_window.nil?
        return false unless retention_window.is_a?(Integer)

        retention_window > 0 || retention_window == EXCLUDED_WINDOW
      end

      # When exclude.reason is set, retention_window and enforcement_strategy must
      # both use their placeholders (-1 and 'none'). When it is not set, neither
      # placeholder is allowed and both fields must carry concrete values.
      def coupling_errors
        if excluded?
          return [] if retention_window == EXCLUDED_WINDOW && enforcement_strategy == EXCLUDED_STRATEGY

          return ["retention_window: #{EXCLUDED_WINDOW} and enforcement_strategy: #{EXCLUDED_STRATEGY} " \
            "are both required when exclude.reason is set"]
        end

        return [] unless retention_window == EXCLUDED_WINDOW || enforcement_strategy == EXCLUDED_STRATEGY

        ["retention_window: #{EXCLUDED_WINDOW} and enforcement_strategy: #{EXCLUDED_STRATEGY} " \
          "are only allowed when exclude.reason is set"]
      end
    end
  end
end
