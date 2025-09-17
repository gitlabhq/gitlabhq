# frozen_string_literal: true

class CreateVirtualRegistriesCleanupPolicies < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    create_table :virtual_registries_cleanup_policies do |t|
      t.references :group, null: false, foreign_key: { to_table: :namespaces, on_delete: :cascade },
        index: { unique: true }
      t.datetime_with_timezone :next_run_at
      t.datetime_with_timezone :last_run_at
      t.bigint :last_run_deleted_size, default: 0
      t.timestamps_with_timezone null: false
      t.integer :keep_n_days_after_download, null: false, default: 30
      t.integer :last_run_deleted_entries_count, default: 0
      t.integer :status, null: false, default: 0, limit: 2
      t.integer :cadence, null: false, default: 7, limit: 2
      t.boolean :enabled, null: false, default: false
      t.boolean :notify_on_success, null: false, default: false
      t.boolean :notify_on_failure, null: false, default: false
      t.text :failure_message, limit: 255
      t.jsonb :last_run_detailed_metrics, default: {}

      t.index :next_run_at, where: 'enabled = true AND status IN (0, 2)',
        name: 'idx_vr_cleanup_policies_on_next_run_at_when_runnable'
      t.check_constraint 'keep_n_days_after_download > 0'
      t.check_constraint 'last_run_deleted_size >= 0'
      t.check_constraint 'last_run_deleted_entries_count >= 0'
      t.check_constraint 'cadence IN (1, 7, 14, 30, 90)'
    end
  end
end
