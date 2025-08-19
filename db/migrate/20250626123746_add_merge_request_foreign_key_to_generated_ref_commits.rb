# frozen_string_literal: true

class AddMergeRequestForeignKeyToGeneratedRefCommits < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.3'

  FK_NAME = 'fk_generated_ref_commits_merge_request_id'
  TABLE_NAME = :p_generated_ref_commits

  def up
    add_concurrent_partitioned_foreign_key TABLE_NAME, :merge_requests,
      column: [:project_id, :merge_request_iid],
      target_column: [:target_project_id, :iid],
      on_delete: :cascade,
      name: FK_NAME,
      reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(TABLE_NAME, column: :merge_request_iid,
        name: FK_NAME, reverse_lock_order: true)
    end
  end
end
