# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module CascadingNamespaceSettings
        include Gitlab::Database::MigrationHelpers

        # Creates the four required columns that constitutes a single cascading
        # namespace settings attribute. This helper is only appropriate if the
        # setting is not already present as a non-cascading attribute.
        #
        # Creates the `setting_name` column along with the `lock_setting_name`
        # column in both `namespace_settings` and `application_settings`.
        #
        # This helper is not reversible and must be defined in conjunction with
        # `remove_cascading_namespace_setting` in separate up and down directions.
        #
        # setting_name - The name of the cascading attribute - same as defined
        #                in `NamespaceSetting` with the `cascading_attr` method.
        # type - The column type for the setting itself (:boolean, :integer, etc.)
        # options - Standard Rails column options hash. Accepts keys such as
        #           `null` and `default`.
        #
        # `null` and `default` options will only be applied to the `application_settings`
        # column. In most cases, a non-null default value should be specified.
        def add_cascading_namespace_setting(setting_name, type, **options)
          lock_column_name = "lock_#{setting_name}".to_sym

          check_cascading_namespace_setting_consistency(setting_name, lock_column_name)

          namespace_options = options.merge(null: true, default: nil)

          add_column(:namespace_settings, setting_name, type, **namespace_options)
          add_column(:namespace_settings, lock_column_name, :boolean, default: false, null: false)

          add_column(:application_settings, setting_name, type, **options)
          add_column(:application_settings, lock_column_name, :boolean, default: false, null: false)
        end

        def remove_cascading_namespace_setting(setting_name)
          lock_column_name = "lock_#{setting_name}".to_sym

          remove_column(:namespace_settings, setting_name) if column_exists?(:namespace_settings, setting_name)
          remove_column(:namespace_settings, lock_column_name) if column_exists?(:namespace_settings, lock_column_name)

          remove_column(:application_settings, setting_name) if column_exists?(:application_settings, setting_name)
          remove_column(:application_settings, lock_column_name) if column_exists?(:application_settings, lock_column_name)
        end

        private

        def check_cascading_namespace_setting_consistency(setting_name, lock_name)
          existing_columns = []

          %w[namespace_settings application_settings].each do |table|
            existing_columns << "#{table}.#{setting_name}" if column_exists?(table.to_sym, setting_name)
            existing_columns << "#{table}.#{lock_name}" if column_exists?(table.to_sym, lock_name)
          end

          return if existing_columns.empty?

          raise <<~ERROR
          One or more cascading namespace columns already exist. `add_cascading_namespace_setting` helper
          can only be used for new settings, when none of the required columns already exist.
          Existing columns: #{existing_columns.join(', ')}
          ERROR
        end
      end
    end
  end
end
