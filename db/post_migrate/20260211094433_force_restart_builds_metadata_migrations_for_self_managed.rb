# frozen_string_literal: true

class ForceRestartBuildsMetadataMigrationsForSelfManaged < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  milestone '18.8'
  disable_ddl_transaction!

  MIGRATION = 'MoveCiBuildsMetadataSelfManaged'

  def up
    each_partition do |partition, ids|
      migration = Gitlab::Database::BackgroundMigration::BatchedMigration.find_for_configuration(
        gitlab_schema_from_context, MIGRATION, partition.identifier, :id, [:partition_id, ids],
        include_compatible: true
      )

      next unless migration

      migration.reset_attempts_of_blocked_jobs!
      migration.execute! if migration.failed?
    end
  end

  def down; end

  private

  def each_partition
    Gitlab::Database::PostgresPartitionedTable.each_partition(:p_ci_builds) do |partition|
      ids = partition.list_partition_ids

      yield(partition, ids)
    end
  end
end
