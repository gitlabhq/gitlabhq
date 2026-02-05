# frozen_string_literal: true

class UpdateSubBatchSizeForMoveCiBuildsMetadata < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    return unless Gitlab.com_except_jh?

    each_partition do |partition, ids|
      migration = find_migration(partition, ids)

      migration&.update!(sub_batch_size: 250)
    end
  end

  def down
    return unless Gitlab.com_except_jh?

    each_partition do |partition, ids|
      migration = find_migration(partition, ids)

      migration&.update!(sub_batch_size: 100)
    end
  end

  private

  def each_partition
    Gitlab::Database::PostgresPartitionedTable.each_partition(:p_ci_builds) do |partition|
      ids = partition.list_partition_ids

      yield(partition, ids)
    end
  end

  def find_migration(partition, ids)
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .find_for_configuration(:gitlab_ci, 'MoveCiBuildsMetadata',
        partition.identifier, :id, [:partition_id, ids],
        include_compatible: true
      )
  end
end
