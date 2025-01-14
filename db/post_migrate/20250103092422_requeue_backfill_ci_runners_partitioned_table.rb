# frozen_string_literal: true

class RequeueBackfillCiRunnersPartitionedTable < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.8'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'BackfillCiRunnersPartitionedTable'
  TABLE_NAME = 'ci_runners'

  def up
    cleanup_partitioning_data_migration TABLE_NAME, MIGRATION

    enqueue_partitioning_data_migration TABLE_NAME, MIGRATION
  end

  def down
    cleanup_partitioning_data_migration TABLE_NAME, MIGRATION
  end
end
