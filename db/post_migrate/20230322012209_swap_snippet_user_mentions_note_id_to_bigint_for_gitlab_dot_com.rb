# frozen_string_literal: true

class SwapSnippetUserMentionsNoteIdToBigintForGitlabDotCom < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = 'snippet_user_mentions'

  def up
    return unless should_run?

    swap
  end

  def down
    return unless should_run?

    swap
  end

  def swap
    # This will replace the existing index_snippet_user_mentions_on_note_id
    add_concurrent_index TABLE_NAME, :note_id_convert_to_bigint, unique: true,
      name: 'index_snippet_user_mentions_on_note_id_convert_to_bigint',
      where: 'note_id_convert_to_bigint IS NOT NULL'

    # This will replace the existing snippet_user_mentions_on_snippet_id_and_note_id_index
    add_concurrent_index TABLE_NAME, [:snippet_id, :note_id_convert_to_bigint], unique: true,
      name: 'tmp_snippet_user_mentions_on_snippet_id_and_note_id_index'

    # This will replace the existing snippet_user_mentions_on_snippet_id_index
    add_concurrent_index TABLE_NAME, :snippet_id, unique: true,
      name: 'tmp_snippet_user_mentions_on_snippet_id_index',
      where: 'note_id_convert_to_bigint IS NULL'

    # This will replace the existing fk_rails_4d3f96b2cb
    add_concurrent_foreign_key TABLE_NAME, :notes, column: :note_id_convert_to_bigint,
      name: 'fk_snippet_user_mentions_note_id_convert_to_bigint',
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

      execute 'DROP INDEX IF EXISTS index_snippet_user_mentions_on_note_id'
      rename_index TABLE_NAME, 'index_snippet_user_mentions_on_note_id_convert_to_bigint',
        'index_snippet_user_mentions_on_note_id'

      execute 'DROP INDEX IF EXISTS snippet_user_mentions_on_snippet_id_and_note_id_index'
      rename_index TABLE_NAME, 'tmp_snippet_user_mentions_on_snippet_id_and_note_id_index',
        'snippet_user_mentions_on_snippet_id_and_note_id_index'

      execute 'DROP INDEX IF EXISTS snippet_user_mentions_on_snippet_id_index'
      rename_index TABLE_NAME, 'tmp_snippet_user_mentions_on_snippet_id_index',
        'snippet_user_mentions_on_snippet_id_index'

      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT IF EXISTS fk_rails_4d3f96b2cb"
      rename_constraint(TABLE_NAME, 'fk_snippet_user_mentions_note_id_convert_to_bigint', 'fk_rails_4d3f96b2cb')
    end
  end

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
