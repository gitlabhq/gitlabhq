# frozen_string_literal: true

class DropProjectDailyStatisticsArchived < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '18.9'

  disable_ddl_transaction!

  TABLE_NAME = :project_daily_statistics
  ARCHIVED_TABLE_NAME = "#{TABLE_NAME}_archived"

  def up
    # Remove foreign key constraint
    with_lock_retries(raise_on_exhaustion: true) do
      remove_foreign_key_if_exists(ARCHIVED_TABLE_NAME, name: 'fk_rails_8e549b272d')
    end

    # Drop the archived table
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- helper method over allowed drop_table
    with_lock_retries do
      drop_nonpartitioned_archive_table(TABLE_NAME) if table_exists?(ARCHIVED_TABLE_NAME)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  def down
    # Recreate the archived table
    recreate_archive_table unless table_exists?(ARCHIVED_TABLE_NAME)

    # Re-add the foreign key constraint
    add_concurrent_foreign_key(
      ARCHIVED_TABLE_NAME,
      :projects,
      column: :project_id,
      name: 'fk_rails_8e549b272d',
      on_delete: :cascade
    )

    # Recreate the sync trigger
    with_lock_retries do
      create_trigger_to_sync_tables(TABLE_NAME, ARCHIVED_TABLE_NAME, 'id')
    end
  end

  private

  def recreate_archive_table
    execute(<<~SQL)
      CREATE TABLE #{ARCHIVED_TABLE_NAME} (
        id bigint NOT NULL,
        project_id bigint NOT NULL,
        fetch_count integer NOT NULL,
        date date
      );

      ALTER TABLE ONLY #{ARCHIVED_TABLE_NAME} ADD CONSTRAINT #{ARCHIVED_TABLE_NAME}_pkey PRIMARY KEY (id);

      CREATE INDEX index_project_daily_statistics_on_date_and_id ON #{ARCHIVED_TABLE_NAME} USING btree (date, id);
      CREATE UNIQUE INDEX index_project_daily_statistics_on_project_id_and_date ON #{ARCHIVED_TABLE_NAME} USING btree (project_id, date DESC);
    SQL
  end
end
