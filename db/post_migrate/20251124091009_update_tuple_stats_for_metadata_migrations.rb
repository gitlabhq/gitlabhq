# frozen_string_literal: true

class UpdateTupleStatsForMetadataMigrations < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  disable_ddl_transaction!

  MIGRATIONS = %w[
    MoveCiBuildsMetadata
    MoveCiBuildsMetadataSelfManaged
  ]

  def up
    Gitlab::Database::SharedModel.using_connection(connection) do
      Gitlab::Database::BackgroundMigration::BatchedMigration.for_job_class(MIGRATIONS).each do |migration|
        table_stats = Gitlab::Database::PgClass
          .joins('LEFT JOIN pg_stat_user_tables ON pg_stat_user_tables.relid = pg_class.oid')
          .find_by('schemaname = ? AND pg_class.relname = ?', *migration.table_name.split('.'))

        tuples = table_stats&.cardinality_estimate

        migration.update!(total_tuple_count: tuples)
      end
    end
  end

  def down; end
end
