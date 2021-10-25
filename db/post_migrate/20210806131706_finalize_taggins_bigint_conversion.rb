# frozen_string_literal: true

class FinalizeTagginsBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = 'taggings'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [%w[id taggable_id], %w[id_convert_to_bigint taggable_id_convert_to_bigint]]
    )

    swap
  end

  def down
    swap
  end

  private

  def swap
    # rubocop:disable Migration/PreventIndexCreation
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: 'index_taggings_on_id_convert_to_bigint'

    # This is to replace the existing "index_taggings_on_taggable_id_and_taggable_type" btree (taggable_id, taggable_type)
    add_concurrent_index TABLE_NAME, [:taggable_id_convert_to_bigint, :taggable_type], name: 'i_taggings_on_taggable_id_convert_to_bigint_and_taggable_type'

    # This is to replace the existing "index_taggings_on_taggable_id_and_taggable_type_and_context" btree (taggable_id, taggable_type, context)
    add_concurrent_index TABLE_NAME, [:taggable_id_convert_to_bigint, :taggable_type, :context], name: 'i_taggings_on_taggable_bigint_and_taggable_type_and_context'

    # This is to replace the existing "taggings_idx" btree (tag_id, taggable_id, taggable_type, context, tagger_id, tagger_type)
    add_concurrent_index TABLE_NAME, [:tag_id, :taggable_id_convert_to_bigint, :taggable_type, :context, :tagger_id, :tagger_type], unique: true, name: 'taggings_idx_tmp'

    # This is to replace the existing "tmp_index_taggings_on_id_where_taggable_type_project" btree (id) WHERE taggable_type::text = 'Project'::text
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, where: "taggable_type = 'Project'", name: 'tmp_index_taggings_on_id_bigint_where_taggable_type_project'
    # rubocop:enable Migration/PreventIndexCreation

    with_lock_retries(raise_on_exhaustion: true) do
      # We'll need  ACCESS EXCLUSIVE lock on the related tables,
      # lets make sure it can be acquired from the start
      execute "LOCK TABLE #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      # Swap column names
      temp_name = 'taggable_id_tmp'
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:taggable_id)} TO #{quote_column_name(temp_name)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:taggable_id_convert_to_bigint)} TO #{quote_column_name(:taggable_id)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(temp_name)} TO #{quote_column_name(:taggable_id_convert_to_bigint)}"

      temp_name = 'id_tmp'
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:id)} TO #{quote_column_name(temp_name)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:id_convert_to_bigint)} TO #{quote_column_name(:id)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(temp_name)} TO #{quote_column_name(:id_convert_to_bigint)}"

      # We need to update the trigger function in order to make PostgreSQL to
      # regenerate the execution plan for it. This is to avoid type mismatch errors like
      # "type of parameter 15 (bigint) does not match that when preparing the plan (integer)"
      function_name = Gitlab::Database::UnidirectionalCopyTrigger.on_table(TABLE_NAME, connection: connection).name([:id, :taggable_id], [:id_convert_to_bigint, :taggable_id_convert_to_bigint])
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      # Swap defaults
      execute "ALTER SEQUENCE taggings_id_seq OWNED BY #{TABLE_NAME}.id"
      change_column_default TABLE_NAME, :id, -> { "nextval('taggings_id_seq'::regclass)" }
      change_column_default TABLE_NAME, :id_convert_to_bigint, 0

      # Swap PK constraint
      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT taggings_pkey CASCADE"
      rename_index TABLE_NAME, 'index_taggings_on_id_convert_to_bigint', 'taggings_pkey'
      execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT taggings_pkey PRIMARY KEY USING INDEX taggings_pkey"

      # Rename the index on the `bigint` column to match the new column name
      # (we already hold an exclusive lock, so no need to use DROP INDEX CONCURRENTLY here)
      execute 'DROP INDEX IF EXISTS index_taggings_on_taggable_id_and_taggable_type'
      rename_index TABLE_NAME, 'i_taggings_on_taggable_id_convert_to_bigint_and_taggable_type', 'index_taggings_on_taggable_id_and_taggable_type'
      execute 'DROP INDEX IF EXISTS index_taggings_on_taggable_id_and_taggable_type_and_context'
      rename_index TABLE_NAME, 'i_taggings_on_taggable_bigint_and_taggable_type_and_context', 'index_taggings_on_taggable_id_and_taggable_type_and_context'
      execute 'DROP INDEX IF EXISTS taggings_idx'
      rename_index TABLE_NAME, 'taggings_idx_tmp', 'taggings_idx'
      execute 'DROP INDEX IF EXISTS tmp_index_taggings_on_id_where_taggable_type_project'
      rename_index TABLE_NAME, 'tmp_index_taggings_on_id_bigint_where_taggable_type_project', 'tmp_index_taggings_on_id_where_taggable_type_project'
    end
  end
end
