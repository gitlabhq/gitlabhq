# frozen_string_literal: true

class FinalizeEventsBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = 'events'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [["id"], ["id_convert_to_bigint"]]
    )

    swap
  end

  def down
    swap
  end

  private

  def swap
    # This is to replace the existing "events_pkey" PRIMARY KEY, btree (id)
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: 'index_events_on_id_convert_to_bigint'
    # This is to replace the existing "index_events_on_project_id_and_id" btree (project_id, id)
    add_concurrent_index TABLE_NAME, [:project_id, :id_convert_to_bigint], name: 'index_events_on_project_id_and_id_convert_to_bigint'
    # This is to replace the existing "index_events_on_project_id_and_id_desc_on_merged_action" btree (project_id, id DESC) WHERE action = 7
    add_concurrent_index TABLE_NAME, [:project_id, :id_convert_to_bigint], order: { id_convert_to_bigint: :desc },
                                                                           where: "action = 7", name: 'index_events_on_project_id_and_id_bigint_desc_on_merged_action'

    # Add a FK on `push_event_payloads(event_id)` to `id_convert_to_bigint`, the old FK (fk_36c74129da)
    # will be removed when events_pkey constraint is droppped.
    fk_event_id = concurrent_foreign_key_name(:push_event_payloads, :event_id)
    fk_event_id_tmp = "#{fk_event_id}_tmp"
    add_concurrent_foreign_key :push_event_payloads, TABLE_NAME,
      column: :event_id, target_column: :id_convert_to_bigint,
      name: fk_event_id_tmp, on_delete: :cascade, reverse_lock_order: true

    with_lock_retries(raise_on_exhaustion: true) do
      # We'll need  ACCESS EXCLUSIVE lock on the related tables,
      # lets make sure it can be acquired from the start.
      # Lock order should be
      #   1. events
      #   2. push_event_payloads
      # in order to match the order in EventCreateService#create_push_event,
      # and avoid deadlocks.
      execute "LOCK TABLE #{TABLE_NAME}, push_event_payloads IN ACCESS EXCLUSIVE MODE"

      # Swap column names
      temp_name = 'id_tmp'
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:id)} TO #{quote_column_name(temp_name)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:id_convert_to_bigint)} TO #{quote_column_name(:id)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(temp_name)} TO #{quote_column_name(:id_convert_to_bigint)}"

      # We need to update the trigger function in order to make PostgreSQL to
      # regenerate the execution plan for it. This is to avoid type mismatch errors like
      # "type of parameter 15 (bigint) does not match that when preparing the plan (integer)"
      function_name = Gitlab::Database::UnidirectionalCopyTrigger.on_table(TABLE_NAME, connection: connection).name(:id, :id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      # Swap defaults
      execute "ALTER SEQUENCE events_id_seq OWNED BY #{TABLE_NAME}.id"
      change_column_default TABLE_NAME, :id, -> { "nextval('events_id_seq'::regclass)" }
      change_column_default TABLE_NAME, :id_convert_to_bigint, 0

      # Swap PK constraint
      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT events_pkey CASCADE" # this will drop fk_36c74129da
      rename_index TABLE_NAME, 'index_events_on_id_convert_to_bigint', 'events_pkey'
      execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT events_pkey PRIMARY KEY USING INDEX events_pkey"

      # Rename the rest of the indexes (we already hold an exclusive lock, so no need to use DROP INDEX CONCURRENTLY here
      execute 'DROP INDEX index_events_on_project_id_and_id'
      rename_index TABLE_NAME, 'index_events_on_project_id_and_id_convert_to_bigint', 'index_events_on_project_id_and_id'
      execute 'DROP INDEX index_events_on_project_id_and_id_desc_on_merged_action'
      rename_index TABLE_NAME, 'index_events_on_project_id_and_id_bigint_desc_on_merged_action', 'index_events_on_project_id_and_id_desc_on_merged_action'

      # Change the name of the temporary FK
      rename_constraint(:push_event_payloads, fk_event_id_tmp, fk_event_id)
    end
  end
end
