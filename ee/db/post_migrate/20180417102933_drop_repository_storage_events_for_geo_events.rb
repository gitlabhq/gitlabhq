# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropRepositoryStorageEventsForGeoEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 5_000
  TABLES = %i(geo_hashed_storage_migrated_events geo_repository_created_events
              geo_repository_deleted_events geo_repository_renamed_events)

  def up
    TABLES.each { |t| remove_column(t, :repository_storage_path) }
  end

  def down
    TABLES.each { |t| add_column(t, :repository_storage_path, :text) }

    add_shard_path
  end

  private

  def add_shard_path
    TABLES.each do |t|
      min_id = 0

      loop do
        newest = newest_entry(t)
        break unless newest
        break if newest['repository_storage_path'].present?

        new_batch = batch(t, min_id)
        update_batch(t, new_batch)

        min_id = new_batch.last.to_i
      end

      change_column_null(t, :repository_storage_path, true)
    end
  end

  def newest_entry(table)
    execute(
      <<~SQL
      SELECT id, repository_storage_path
      FROM #{table}
      ORDER BY id DESC
      LIMIT 1;
      SQL
    ).first
  end

  def batch(table, min_id)
    execute(
      <<~SQL
        SELECT id
        FROM #{table}
        WHERE id > #{min_id}
        ORDER BY id ASC
        LIMIT #{BATCH_SIZE};
      SQL
    ).map { |row| row['id'] }
  end

  def update_batch(table, ids)
    execute(
      <<~SQL
      UPDATE #{table}
      SET repository_storage_path =
        CASE repository_storage_name
          #{case_statements}
        END
      WHERE id IN (#{ids.join(',')})
      SQL
    )
  end

  def case_statements
    statement = ""
    Gitlab.config.repositories.storages.each do |shard, data|
      statement << "WHEN '#{shard}' THEN '#{data.legacy_disk_path}'\n"
    end

    statement
  end
end
