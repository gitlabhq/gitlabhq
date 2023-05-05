# frozen_string_literal: true

class AddPackageFilesLimitToApplicationSettings < Gitlab::Database::Migration[1.0]
  def change
    add_column :application_settings, :max_package_files_for_package_destruction, :smallint, default: 100, null: false
  end
end
