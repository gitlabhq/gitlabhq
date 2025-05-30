# frozen_string_literal: true

# This module provides helper methods for migrating `ops` type feature flags to application settings.
# It handles regular application settings and JSONB column application settings.
# The module includes methods for:
# - Migrating feature flag state to application settings during migrations (up)
# - Reverting application settings to default values during rollbacks (down)
#
# WARNING: These helpers will only migrate feature flags that are explicitly set to `true` or `false`.
# If a feature flag is set for a percentage or specific actor, the default value will be used.

module Gitlab
  module Database
    module MigrationHelpers
      module FeatureFlagMigratorHelpers
        # Migrates a feature flag to an application setting.
        #
        # @param feature_flag_name [Symbol, String] The name of the feature flag to migrate
        # @param setting_name [Symbol, String] The name of the application setting column to update
        # @param default_enabled [Boolean] The default value to use if the feature flag is not set
        # @return [Integer] The number of affected rows for UPDATE statement
        def up_migrate_to_setting(feature_flag_name:, setting_name:, default_enabled:)
          if feature_flag_name.blank? || setting_name.blank? || default_enabled.nil?
            raise ArgumentError, 'feature_flag_name, setting_name, and default_enabled are required'
          end

          raise ArgumentError, 'default_enabled must be a boolean' unless [true, false].include?(default_enabled)

          feature_flag_state = feature_flag_state(feature_flag_name, default_enabled)

          sql = <<~SQL
            UPDATE application_settings
            SET #{setting_name} = #{feature_flag_state}, updated_at = NOW()
            WHERE id = (SELECT MAX(id) FROM application_settings)
          SQL

          execute(sql)
        end

        # Migrates a feature flag to a JSONB application setting.
        #
        # @param feature_flag_name[Symbol, String] The name of the feature flag to migrate
        # @param setting_name [Symbol, String] The name of the application setting to update
        # @param jsonb_column_name [Symbol, String] The name of the application setting JSONB column to update
        # @param default_enabled [Boolean] The default value to use if the feature flag is not set
        # @return [Integer] The number of affected rows for UPDATE statement
        def up_migrate_to_jsonb_setting(feature_flag_name:, setting_name:, jsonb_column_name:, default_enabled:)
          if feature_flag_name.blank? || setting_name.blank? || jsonb_column_name.blank? || default_enabled.nil?
            raise ArgumentError, 'feature_flag_name, jsonb_column_name, setting_name, and default_enabled are required'
          end

          raise ArgumentError, 'default_enabled must be a boolean' unless [true, false].include?(default_enabled)

          feature_flag_state = feature_flag_state(feature_flag_name, default_enabled)

          sql = <<~SQL
            UPDATE application_settings
            SET #{jsonb_column_name} = jsonb_set(
              COALESCE(#{jsonb_column_name}, '{}'::jsonb),
              '{#{setting_name}}',
              to_jsonb(#{feature_flag_state})
            ),
            updated_at = NOW()
            WHERE id = (SELECT MAX(id) FROM application_settings)
          SQL

          execute(sql)
        end

        # Reverts an application setting to its default value during a migration rollback.
        #
        # @param setting_name [Symbol, String] The name of the application setting column to revert
        # @param default_enabled [Boolean] The default value to set for the application setting
        # @return [Integer] The number of affected rows for UPDATE statement
        def down_migrate_to_setting(setting_name:, default_enabled:)
          if setting_name.blank? || default_enabled.nil?
            raise ArgumentError, 'setting_name and default_enabled are required'
          end

          raise ArgumentError, 'default_enabled must be a boolean' unless [true, false].include?(default_enabled)

          sql = <<~SQL
            UPDATE application_settings
            SET #{setting_name} = #{default_enabled}, updated_at = NOW()
            WHERE id = (SELECT MAX(id) FROM application_settings)
          SQL

          execute(sql)
        end

        # Reverts a JSONB application setting to its default state during a migration rollback.
        # This method removes the specified setting from the JSONB column.
        #
        # @param setting_name [Symbol, String] The name of the application setting to remove from the JSONB column
        # @param jsonb_column_name [Symbol, String] The name of the application setting JSONB column to update
        # @return [Integer] The number of affected rows for UPDATE statement
        def down_migrate_to_jsonb_setting(setting_name:, jsonb_column_name:)
          if setting_name.blank? || jsonb_column_name.nil?
            raise ArgumentError, 'setting_name and jsonb_column_name are required'
          end

          sql = <<~SQL
            UPDATE application_settings
            SET #{jsonb_column_name} = #{jsonb_column_name} - '#{setting_name}',
            updated_at = NOW()
            WHERE id = (SELECT MAX(id) FROM application_settings)
          SQL

          execute(sql)
        end

        private

        def validate_all_arguments_present!(*args, error_msg)
          return if args.all? { |arg| !arg.nil? }

          raise ArgumentError, error_msg
        end

        def feature_flag_state(feature_flag_name, default_enabled)
          # no record of feature flag being set, return default_enabled
          return default_enabled unless exists_in_features?(feature_flag_name)

          set_to_true_in_feature_gates?(feature_flag_name)
        end

        def feature_gates
          @feature_gates ||= DynamicModelHelpers.define_batchable_model('feature_gates',
            connection: ActiveRecord::Base.connection) # rubocop:disable Database/MultipleDatabases -- Flipper models do not inherit from ApplicationRecord
        end

        def features
          @features ||= DynamicModelHelpers.define_batchable_model('features',
            connection: ActiveRecord::Base.connection) # rubocop:disable Database/MultipleDatabases -- Flipper models do not inherit from ApplicationRecord
        end

        def exists_in_features?(feature_flag_name)
          features.where(key: feature_flag_name).exists?
        end

        def set_to_true_in_feature_gates?(feature_flag_name)
          feature_gates.where(feature_key: feature_flag_name, key: 'boolean', value: 'true').exists?
        end
      end
    end
  end
end
