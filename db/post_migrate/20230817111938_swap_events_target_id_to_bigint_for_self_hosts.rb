# frozen_string_literal: true

class SwapEventsTargetIdToBigintForSelfHosts < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = 'events'

  def up
    return if com_or_dev_or_test_but_not_jh?
    return if temp_column_removed?(TABLE_NAME, :target_id)
    return if columns_swapped?(TABLE_NAME, :target_id)

    swap
  end

  def down
    return if com_or_dev_or_test_but_not_jh?
    return if temp_column_removed?(TABLE_NAME, :target_id)
    return unless columns_swapped?(TABLE_NAME, :target_id)

    swap
  end

  private

  def swap
    # This will replace the existing index_events_on_target_type_and_target_id_and_fingerprint
    add_concurrent_index TABLE_NAME, [:target_type, :target_id_convert_to_bigint, :fingerprint],
      name: :index_events_on_target_type_and_target_id_bigint_fingerprint,
      unique: true

    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN target_id TO target_id_tmp"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN target_id_convert_to_bigint TO target_id"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN target_id_tmp TO target_id_convert_to_bigint"

      function_name = Gitlab::Database::UnidirectionalCopyTrigger
        .on_table(TABLE_NAME, connection: connection)
        .name(:target_id, :target_id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      execute 'DROP INDEX IF EXISTS index_events_on_target_type_and_target_id_and_fingerprint'
      rename_index TABLE_NAME, 'index_events_on_target_type_and_target_id_bigint_fingerprint',
        'index_events_on_target_type_and_target_id_and_fingerprint'
    end
  end
end
