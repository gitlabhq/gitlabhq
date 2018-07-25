# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropRepositoryStorageEventsForGeoEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false
  TABLES = %i(geo_hashed_storage_migrated_events geo_repository_created_events
              geo_repository_deleted_events geo_repository_renamed_events)

  def up
    transaction do
      TABLES.each { |t| remove_column(t, :repository_storage_path) }
    end
  end

  def down
    TABLES.each do |t|
      add_column(t, :repository_storage_path, :text)

      update_repository_storage_path(t)

      change_column_null(t, :repository_storage_path, true)
    end
  end

  private

  def update_repository_storage_path(table)
    # rubocop:disable Migration/UpdateColumnInBatches
    update_column_in_batches(table, :repository_storage_path, update_statement) do |t, q|
      q.where(t[:repository_storage_path].eq(nil))
    end
  end

  def update_statement
    Arel.sql(
      <<~SQL
        CASE repository_storage_name
          #{case_statements}
        END
      SQL
    )
  end

  def case_statements
    @case_statements ||= Gitlab.config.repositories.storages.map do |shard, data|
      "WHEN '#{shard}' THEN '#{data.legacy_disk_path}'"
    end.join("\n")
  end
end
