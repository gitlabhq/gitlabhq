# frozen_string_literal: true

class AddStatusToPackagesPackageFiles < Gitlab::Database::Migration[1.0]
  def change
    add_column :packages_package_files, :status, :smallint, default: 0, null: false
  end
end
