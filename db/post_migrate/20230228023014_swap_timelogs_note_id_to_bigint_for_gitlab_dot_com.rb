# frozen_string_literal: true

class SwapTimelogsNoteIdToBigintForGitlabDotCom < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = 'timelogs'

  def up
    return unless should_run?

    swap
  end

  def down
    return unless should_run?

    swap
  end

  def swap
    # This will replace the existing index_timelogs_on_note_id
    add_concurrent_index TABLE_NAME, :note_id_convert_to_bigint, name: 'index_timelogs_on_note_id_convert_to_bigint'

    # This will replace the existing fk_timelogs_note_id
    add_concurrent_foreign_key :timelogs, :notes, column: :note_id_convert_to_bigint,
      name: 'fk_timelogs_note_id_convert_to_bigint',
      on_delete: :nullify

    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE notes, #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN note_id TO note_id_tmp"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN note_id_convert_to_bigint TO note_id"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN note_id_tmp TO note_id_convert_to_bigint"

      function_name = Gitlab::Database::UnidirectionalCopyTrigger
        .on_table(TABLE_NAME, connection: connection)
        .name(:note_id, :note_id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      execute "DROP INDEX IF EXISTS index_timelogs_on_note_id"
      rename_index TABLE_NAME, 'index_timelogs_on_note_id_convert_to_bigint', 'index_timelogs_on_note_id'

      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT IF EXISTS fk_timelogs_note_id"
      rename_constraint(TABLE_NAME, 'fk_timelogs_note_id_convert_to_bigint', 'fk_timelogs_note_id')
    end
  end

  private

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
