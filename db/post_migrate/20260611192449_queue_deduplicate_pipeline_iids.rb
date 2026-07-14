# frozen_string_literal: true

class QueueDeduplicatePipelineIids < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  skip_require_disable_ddl_transactions!

  MIGRATION = 'DeduplicatePipelineIids'
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100
  TABLE_NAME = :p_ci_pipelines
  # On GitLab.com the duplicates are confined to partition_ids <= 107 and have been static ever since
  # duplicate iids were fully prevented in %18.10 with https://gitlab.com/gitlab-org/gitlab/-/work_items/582338.
  GITLAB_COM_LAST_DUP_PARTITION_ID = 107

  # We queue one BBM instance per physical partition, batching through each by id. The duplicate
  # check probes only the lower partitions (partition_id < current). Partitions are enqueued from
  # last to first so the smaller, recent partitions complete and release BBM workers sooner.
  def up
    each_partition do |partition, partition_ids|
      next if empty_partition?(partition_ids)
      next if skip_on_gitlab_com?(partition_ids)

      queue_batched_background_migration(
        MIGRATION,
        partition.identifier,
        :id,
        partition_ids,
        batch_size: BATCH_SIZE,
        sub_batch_size: SUB_BATCH_SIZE
      )
    end
  end

  def down
    each_partition do |partition, partition_ids|
      delete_batched_background_migration(
        MIGRATION,
        partition.identifier,
        :id,
        [partition_ids]
      )
    end
  end

  private

  def each_partition
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME).to_a.reverse_each do |partition|
      yield(partition, partition.list_partition_ids)
    end
  end

  def empty_partition?(partition_ids)
    !connection.select_value(ActiveRecord::Base.sanitize_sql_array([<<~SQL, partition_ids]))
      SELECT true FROM #{TABLE_NAME} WHERE partition_id IN (?) LIMIT 1;
    SQL
  end

  def skip_on_gitlab_com?(partition_ids)
    Gitlab.com_except_jh? && partition_ids.min > GITLAB_COM_LAST_DUP_PARTITION_ID
  end

  # Workaround to allow a single migration to enqueue multiple background migrations
  def assign_attributes_safely(migration, max_batch_size, batch_table_name, gitlab_schema, _queued_migration_version)
    super(migration, max_batch_size, batch_table_name, gitlab_schema, nil)
  end
end
