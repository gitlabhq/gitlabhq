# frozen_string_literal: true

class MoveLooseFkDeletedRecordsToDynamicSchema < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    if table_exists?('gitlab_partitions_static.loose_foreign_keys_deleted_records_1')
      execute 'ALTER TABLE gitlab_partitions_static.loose_foreign_keys_deleted_records_1 SET SCHEMA gitlab_partitions_dynamic'
    end
  end

  def down
    if table_exists?('gitlab_partitions_dynamic.loose_foreign_keys_deleted_records_1')
      execute 'ALTER TABLE gitlab_partitions_dynamic.loose_foreign_keys_deleted_records_1 SET SCHEMA gitlab_partitions_static'
    end
  end
end
