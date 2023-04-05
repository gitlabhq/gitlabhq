# frozen_string_literal: true

class SwapNoteDiffFilesNoteIdToBigintForGitlabDotCom < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = 'note_diff_files'

  def up
    return unless should_run?

    swap
  end

  def down
    return unless should_run?

    swap

    add_concurrent_index TABLE_NAME, :diff_note_id_convert_to_bigint, unique: true,
      name: 'index_note_diff_files_on_diff_note_id_convert_to_bigint'

    add_concurrent_foreign_key TABLE_NAME, :notes, column: :diff_note_id_convert_to_bigint,
      name: 'fk_note_diff_files_diff_note_id_convert_to_bigint',
      on_delete: :cascade,
      validate: false
  end

  def swap
    # This will replace the existing index_note_diff_files_on_diff_note_id
    add_concurrent_index TABLE_NAME, :diff_note_id_convert_to_bigint, unique: true,
      name: 'index_note_diff_files_on_diff_note_id_convert_to_bigint'

    # This will replace the existing fk_rails_3d66047aeb
    add_concurrent_foreign_key TABLE_NAME, :notes, column: :diff_note_id_convert_to_bigint,
      name: 'fk_note_diff_files_diff_note_id_convert_to_bigint',
      on_delete: :cascade

    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE notes, #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN diff_note_id TO diff_note_id_tmp"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN diff_note_id_convert_to_bigint TO diff_note_id"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN diff_note_id_tmp TO diff_note_id_convert_to_bigint"

      function_name = Gitlab::Database::UnidirectionalCopyTrigger
        .on_table(TABLE_NAME, connection: connection)
        .name(:diff_note_id, :diff_note_id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      # Swap defaults
      change_column_default TABLE_NAME, :diff_note_id, nil
      change_column_default TABLE_NAME, :diff_note_id_convert_to_bigint, 0

      execute 'DROP INDEX IF EXISTS index_note_diff_files_on_diff_note_id'
      rename_index TABLE_NAME, 'index_note_diff_files_on_diff_note_id_convert_to_bigint',
        'index_note_diff_files_on_diff_note_id'

      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT IF EXISTS fk_rails_3d66047aeb"
      rename_constraint(TABLE_NAME, 'fk_note_diff_files_diff_note_id_convert_to_bigint', 'fk_rails_3d66047aeb')
    end
  end

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
