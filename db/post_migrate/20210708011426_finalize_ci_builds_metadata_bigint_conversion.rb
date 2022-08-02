# frozen_string_literal: true

class FinalizeCiBuildsMetadataBigintConversion < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TABLE_NAME = 'ci_builds_metadata'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [["id"], ["id_convert_to_bigint"]]
    )

    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [["build_id"], ["build_id_convert_to_bigint"]]
    )

    swap
  end

  def down
    swap
  end

  private

  def swap
    # Indexes were pre-created on gitlab.com to avoid slowing down deployments
    #
    # rubocop:disable Migration/PreventIndexCreation
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: 'index_ci_builds_metadata_on_id_convert_to_bigint'
    add_concurrent_index TABLE_NAME, :build_id_convert_to_bigint, where: 'has_exposed_artifacts IS TRUE', name: 'index_ci_builds_metadata_on_build_id_int8_and_exposed_artifacts'
    create_covering_index TABLE_NAME, 'index_ci_builds_metadata_on_build_id_int8_where_interruptible'
    add_concurrent_index TABLE_NAME, :build_id_convert_to_bigint, unique: true, name: 'index_ci_builds_metadata_on_build_id_convert_to_bigint'
    # rubocop:enable Migration/PreventIndexCreation

    add_concurrent_foreign_key TABLE_NAME, :ci_builds, column: :build_id_convert_to_bigint, on_delete: :cascade,
                                                       reverse_lock_order: true

    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE ci_builds, #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      # rubocop:disable Migration/WithLockRetriesDisallowedMethod
      swap_column :id
      swap_column :build_id
      # rubocop:enable Migration/WithLockRetriesDisallowedMethod

      # We need to update the trigger function in order to make PostgreSQL to
      # regenerate the execution plan for it. This is to avoid type mismatch errors like
      # "type of parameter 15 (bigint) does not match that when preparing the plan (integer)"
      execute "ALTER FUNCTION #{quote_table_name(Gitlab::Database::UnidirectionalCopyTrigger.on_table(TABLE_NAME, connection: connection).name(:id, :id_convert_to_bigint))} RESET ALL"
      execute "ALTER FUNCTION #{quote_table_name(Gitlab::Database::UnidirectionalCopyTrigger.on_table(TABLE_NAME, connection: connection).name(:build_id, :build_id_convert_to_bigint))} RESET ALL"

      # Swap defaults for PK
      execute "ALTER SEQUENCE ci_builds_metadata_id_seq OWNED BY #{TABLE_NAME}.id"
      change_column_default TABLE_NAME, :id, -> { "nextval('ci_builds_metadata_id_seq'::regclass)" }
      change_column_default TABLE_NAME, :id_convert_to_bigint, 0

      # Swap defaults for FK
      change_column_default TABLE_NAME, :build_id, nil
      change_column_default TABLE_NAME, :build_id_convert_to_bigint, 0

      # Swap PK constraint
      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT ci_builds_metadata_pkey CASCADE"
      rename_index TABLE_NAME, 'index_ci_builds_metadata_on_id_convert_to_bigint', 'ci_builds_metadata_pkey'
      execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT ci_builds_metadata_pkey PRIMARY KEY USING INDEX ci_builds_metadata_pkey"

      # Rename the rest of the indexes (we already hold an exclusive lock, so no need to use DROP INDEX CONCURRENTLY here)
      # rubocop:disable Migration/WithLockRetriesDisallowedMethod
      swap_index 'index_ci_builds_metadata_on_build_id', 'index_ci_builds_metadata_on_build_id_convert_to_bigint'
      swap_index 'index_ci_builds_metadata_on_build_id_and_has_exposed_artifacts', 'index_ci_builds_metadata_on_build_id_int8_and_exposed_artifacts'
      swap_index 'index_ci_builds_metadata_on_build_id_and_id_and_interruptible', 'index_ci_builds_metadata_on_build_id_int8_where_interruptible'
      # rubocop:enable Migration/WithLockRetriesDisallowedMethod

      # Swap FK constraint
      remove_foreign_key TABLE_NAME, name: concurrent_foreign_key_name(TABLE_NAME, :build_id)
      rename_constraint(
        TABLE_NAME,
        concurrent_foreign_key_name(TABLE_NAME, :build_id_convert_to_bigint),
        concurrent_foreign_key_name(TABLE_NAME, :build_id)
      )
    end
  end

  def swap_index(old, new)
    execute "DROP INDEX #{old}"
    rename_index TABLE_NAME, new, old
  end

  def swap_column(name)
    temp_name = "#{name}_tmp"
    execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(name)} TO #{quote_column_name(temp_name)}"
    execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:"#{name}_convert_to_bigint")} TO #{quote_column_name(name)}"
    execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(temp_name)} TO #{quote_column_name(:"#{name}_convert_to_bigint")}"
  end

  def create_covering_index(table, name)
    return if index_exists_by_name?(table, name)

    disable_statement_timeout do
      execute <<~SQL
        CREATE INDEX CONCURRENTLY #{name}
        ON #{table} (build_id_convert_to_bigint) INCLUDE (id_convert_to_bigint)
        WHERE interruptible = true
      SQL
    end
  end
end
