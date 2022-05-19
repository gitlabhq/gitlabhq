# frozen_string_literal: true

class CreatePackagesCleanupPolicies < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    create_table :packages_cleanup_policies, id: false do |t|
      t.timestamps_with_timezone null: false
      t.references :project,
                   primary_key: true,
                   default: nil,
                   index: false,
                   foreign_key: { to_table: :projects, on_delete: :cascade }
      t.datetime_with_timezone :next_run_at, null: true
      t.text :keep_n_duplicated_package_files, default: 'all', null: false, limit: 255
    end
  end

  def down
    drop_table :packages_cleanup_policies
  end
end
