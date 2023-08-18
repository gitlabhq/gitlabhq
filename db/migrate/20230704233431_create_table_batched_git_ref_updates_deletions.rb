# frozen_string_literal: true

class CreateTableBatchedGitRefUpdatesDeletions < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    options = {
      primary_key: [:id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)',
      if_not_exists: true
    }

    create_table(:p_batched_git_ref_updates_deletions, **options) do |t|
      t.bigserial :id, null: false
      # Do not bother with foreign key as it provides not benefit and has a performance cost. These get cleaned up over
      # time anyway.
      t.bigint :project_id, null: false
      t.bigint :partition_id, null: false, default: 1
      t.timestamps_with_timezone null: false
      t.integer :status, null: false, default: 1, limit: 2
      t.text :ref, null: false, limit: 1024

      t.index [:project_id, :id], where: 'status = 1',
        name: :idx_deletions_on_project_id_and_id_where_pending
    end

    connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.p_batched_git_ref_updates_deletions_1
        PARTITION OF p_batched_git_ref_updates_deletions
        FOR VALUES IN (1);
    SQL
  end

  def down
    drop_table :p_batched_git_ref_updates_deletions
  end
end
