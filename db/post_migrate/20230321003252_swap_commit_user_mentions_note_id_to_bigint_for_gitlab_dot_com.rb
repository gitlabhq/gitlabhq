# frozen_string_literal: true

class SwapCommitUserMentionsNoteIdToBigintForGitlabDotCom < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = 'commit_user_mentions'

  def up
    return unless should_run?

    swap
  end

  def down
    return unless should_run?

    swap
  end

  def swap
    # This will replace the existing commit_user_mentions_on_commit_id_and_note_id_unique_index
    add_concurrent_index TABLE_NAME, [:commit_id, :note_id_convert_to_bigint], unique: true,
      name: 'commit_user_mentions_on_commit_id_and_note_id_convert_to_bigint'

    # This will replace the existing index_commit_user_mentions_on_note_id
    add_concurrent_index TABLE_NAME, :note_id_convert_to_bigint, unique: true,
      name: 'index_commit_user_mentions_on_note_id_convert_to_bigint'

    # This will replace the existing fk_rails_a6760813e0
    add_concurrent_foreign_key TABLE_NAME, :notes, column: :note_id_convert_to_bigint,
      name: 'fk_commit_user_mentions_note_id_convert_to_bigint',
      on_delete: :cascade

    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE notes, #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN note_id TO note_id_tmp"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN note_id_convert_to_bigint TO note_id"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN note_id_tmp TO note_id_convert_to_bigint"

      function_name = Gitlab::Database::UnidirectionalCopyTrigger
        .on_table(TABLE_NAME, connection: connection)
        .name(:note_id, :note_id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      # Swap defaults
      change_column_default TABLE_NAME, :note_id, nil
      change_column_default TABLE_NAME, :note_id_convert_to_bigint, 0

      execute 'DROP INDEX IF EXISTS commit_user_mentions_on_commit_id_and_note_id_unique_index'
      rename_index TABLE_NAME, 'commit_user_mentions_on_commit_id_and_note_id_convert_to_bigint',
        'commit_user_mentions_on_commit_id_and_note_id_unique_index'

      execute 'DROP INDEX IF EXISTS index_commit_user_mentions_on_note_id'
      rename_index TABLE_NAME, 'index_commit_user_mentions_on_note_id_convert_to_bigint',
        'index_commit_user_mentions_on_note_id'

      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT IF EXISTS fk_rails_a6760813e0"
      rename_constraint(TABLE_NAME, 'fk_commit_user_mentions_note_id_convert_to_bigint', 'fk_rails_a6760813e0')
    end
  end

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
