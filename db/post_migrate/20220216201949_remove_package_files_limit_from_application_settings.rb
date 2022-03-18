# frozen_string_literal: true

class RemovePackageFilesLimitFromApplicationSettings < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless column_exists?(:application_settings, :max_package_files_for_package_destruction)

    remove_column :application_settings, :max_package_files_for_package_destruction, :smallint
  end

  def down
    add_column :application_settings, :max_package_files_for_package_destruction, :smallint, default: 100, null: false
    add_check_constraint :application_settings,
                         'max_package_files_for_package_destruction > 0',
                         'app_settings_max_package_files_for_package_destruction_positive'
  end
end
