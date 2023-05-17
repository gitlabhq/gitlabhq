# frozen_string_literal: true

class SwapAwardEmojiNoteIdToBigintForGitlabDotCom < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = 'award_emoji'

  def up
    return unless should_run?

    swap
  end

  def down
    return unless should_run?

    swap
  end

  def swap
    # This will replace the existing idx_award_emoji_on_user_emoji_name_awardable_type_awardable_id
    add_concurrent_index TABLE_NAME, [:user_id, :name, :awardable_type, :awardable_id_convert_to_bigint],
      name: 'tmp_award_emoji_on_user_emoji_name_awardable_type_awardable_id'

    # This will replace the existing index_award_emoji_on_awardable_type_and_awardable_id
    add_concurrent_index TABLE_NAME, [:awardable_type, :awardable_id_convert_to_bigint],
      name: 'tmp_index_award_emoji_on_awardable_type_and_awardable_id'

    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN awardable_id TO awardable_id_tmp"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN awardable_id_convert_to_bigint TO awardable_id"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN awardable_id_tmp TO awardable_id_convert_to_bigint"

      function_name = Gitlab::Database::UnidirectionalCopyTrigger
        .on_table(TABLE_NAME, connection: connection)
        .name(:awardable_id, :awardable_id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      execute 'DROP INDEX IF EXISTS idx_award_emoji_on_user_emoji_name_awardable_type_awardable_id'
      rename_index TABLE_NAME, 'tmp_award_emoji_on_user_emoji_name_awardable_type_awardable_id',
        'idx_award_emoji_on_user_emoji_name_awardable_type_awardable_id'

      execute 'DROP INDEX IF EXISTS index_award_emoji_on_awardable_type_and_awardable_id'
      rename_index TABLE_NAME, 'tmp_index_award_emoji_on_awardable_type_and_awardable_id',
        'index_award_emoji_on_awardable_type_and_awardable_id'
    end
  end

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
