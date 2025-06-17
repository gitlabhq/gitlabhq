# frozen_string_literal: true

class AddForeignKeysToZentaoTrackerData < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :zentao_tracker_data, :project_id, :bigint, if_not_exists: true
      add_column :zentao_tracker_data, :group_id, :bigint, if_not_exists: true
      add_column :zentao_tracker_data, :organization_id, :bigint, if_not_exists: true
    end

    add_concurrent_foreign_key(
      :zentao_tracker_data,
      :projects,
      column: :project_id,
      foreign_key: true,
      on_delete: :cascade,
      validate: false
    )

    add_concurrent_foreign_key(
      :zentao_tracker_data,
      :namespaces,
      column: :group_id,
      foreign_key: true,
      on_delete: :cascade,
      validate: false
    )

    add_concurrent_foreign_key(
      :zentao_tracker_data,
      :organizations,
      column: :organization_id,
      foreign_key: true,
      on_delete: :cascade,
      validate: false
    )
  end

  def down
    with_lock_retries do
      remove_column :zentao_tracker_data, :project_id, if_exists: true
      remove_column :zentao_tracker_data, :group_id, if_exists: true
      remove_column :zentao_tracker_data, :organization_id, if_exists: true
    end
  end
end
