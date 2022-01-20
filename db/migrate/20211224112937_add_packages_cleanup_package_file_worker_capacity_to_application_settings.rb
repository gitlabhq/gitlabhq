# frozen_string_literal: true

class AddPackagesCleanupPackageFileWorkerCapacityToApplicationSettings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :application_settings,
               :packages_cleanup_package_file_worker_capacity,
               :smallint,
               default: 2,
               null: false
  end
end
