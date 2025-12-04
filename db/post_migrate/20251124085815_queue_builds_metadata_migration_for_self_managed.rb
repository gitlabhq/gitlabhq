# frozen_string_literal: true

class QueueBuildsMetadataMigrationForSelfManaged < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  skip_require_disable_ddl_transactions!

  MIGRATION = 'MoveCiBuildsMetadataSelfManaged'
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100
  TABLE_NAME = :p_ci_builds

  def up
    return if Gitlab.com_except_jh?

    each_partition do |partition, ids|
      next if empty_partition?(ids)

      queue_batched_background_migration(
        MIGRATION,
        partition.identifier,
        :id,
        :partition_id,
        ids,
        batch_size: BATCH_SIZE,
        sub_batch_size: SUB_BATCH_SIZE,
        batch_min_value: batch_min_value(ids),
        batch_max_value: batch_max_value(ids)
      )
    end
  end

  def down
    return if Gitlab.com_except_jh?

    each_partition do |partition, ids|
      delete_batched_background_migration(
        MIGRATION,
        partition.identifier,
        :id,
        [:partition_id, ids]
      )
    end
  end

  private

  def each_partition
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME).to_a.reverse_each do |partition|
      ids = partition.condition.scan(/\d+/).map(&:to_i)
      yield(partition, ids)
    end
  end

  def batch_min_value(ids)
    connection.select_value(ActiveRecord::Base.sanitize_sql_array([<<~SQL, ids]))
      SELECT MIN(id) FROM #{TABLE_NAME} WHERE partition_id IN (?);
    SQL
  end

  def batch_max_value(ids)
    connection.select_value(ActiveRecord::Base.sanitize_sql_array([<<~SQL, ids]))
      SELECT MAX(id) FROM #{TABLE_NAME} WHERE partition_id IN (?);
    SQL
  end

  def empty_partition?(ids)
    !connection.select_value(ActiveRecord::Base.sanitize_sql_array([<<~SQL, ids]))
      SELECT true FROM #{TABLE_NAME} WHERE partition_id IN (?) LIMIT 1;
    SQL
  end

  # Workaround to allow a single migration to enqueue multiple background migrations
  def assign_attributes_safely(migration, max_batch_size, batch_table_name, gitlab_schema, _queued_migration_version)
    super(migration, max_batch_size, batch_table_name, gitlab_schema, nil)
  end
end
