# frozen_string_literal: true

class SwapIssueUserMentionsNoteIdToBigintForGitlabDotCom2 < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = 'issue_user_mentions'

  def up
    return unless should_run?
    return if columns_alredy_swapped?

    swap
  end

  def down
    return unless should_run?
    return unless columns_alredy_swapped?

    swap

    add_concurrent_index TABLE_NAME, :note_id_convert_to_bigint, unique: true,
      name: 'index_issue_user_mentions_on_note_id_convert_to_bigint',
      where: 'note_id_convert_to_bigint IS NOT NULL'

    add_concurrent_foreign_key TABLE_NAME, :notes, column: :note_id_convert_to_bigint,
      name: 'fk_issue_user_mentions_note_id_convert_to_bigint',
      on_delete: :cascade,
      validate: false
  end

  def swap
    # This will replace the existing index_issue_user_mentions_on_note_id
    add_concurrent_index TABLE_NAME, :note_id_convert_to_bigint, unique: true,
      name: 'index_issue_user_mentions_on_note_id_convert_to_bigint',
      where: 'note_id_convert_to_bigint IS NOT NULL'

    # This will replace the existing issue_user_mentions_on_issue_id_and_note_id_index
    add_concurrent_index TABLE_NAME, [:issue_id, :note_id_convert_to_bigint], unique: true,
      name: 'tmp_issue_user_mentions_on_issue_id_and_note_id_index'

    # This will replace the existing issue_user_mentions_on_issue_id_index
    add_concurrent_index TABLE_NAME, :issue_id, unique: true,
      name: 'tmp_issue_user_mentions_on_issue_id_index',
      where: 'note_id_convert_to_bigint IS NULL'

    # This will replace the existing fk_rails_3861d9fefa
    add_concurrent_foreign_key TABLE_NAME, :notes, column: :note_id_convert_to_bigint,
      name: 'fk_issue_user_mentions_note_id_convert_to_bigint',
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

      execute 'DROP INDEX IF EXISTS index_issue_user_mentions_on_note_id'
      rename_index TABLE_NAME, 'index_issue_user_mentions_on_note_id_convert_to_bigint',
        'index_issue_user_mentions_on_note_id'

      execute 'DROP INDEX IF EXISTS issue_user_mentions_on_issue_id_and_note_id_index'
      rename_index TABLE_NAME, 'tmp_issue_user_mentions_on_issue_id_and_note_id_index',
        'issue_user_mentions_on_issue_id_and_note_id_index'

      execute 'DROP INDEX IF EXISTS issue_user_mentions_on_issue_id_index'
      rename_index TABLE_NAME, 'tmp_issue_user_mentions_on_issue_id_index',
        'issue_user_mentions_on_issue_id_index'

      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT IF EXISTS fk_rails_3861d9fefa"
      rename_constraint(TABLE_NAME, 'fk_issue_user_mentions_note_id_convert_to_bigint', 'fk_rails_3861d9fefa')
    end
  end

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end

  def columns_alredy_swapped?
    table_columns = columns(TABLE_NAME)
    note_id = table_columns.find { |c| c.name == 'note_id' }
    note_id_convert_to_bigint = table_columns.find { |c| c.name == 'note_id_convert_to_bigint' }

    note_id_convert_to_bigint.sql_type == 'integer' && note_id.sql_type == 'bigint'
  end
end
