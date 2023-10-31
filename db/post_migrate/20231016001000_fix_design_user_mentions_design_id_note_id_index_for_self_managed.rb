# frozen_string_literal: true

class FixDesignUserMentionsDesignIdNoteIdIndexForSelfManaged < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = 'design_user_mentions'
  INDEX_NAME = 'design_user_mentions_on_design_id_and_note_id_unique_index'

  def up
    return if com_or_dev_or_test_but_not_jh?
    return if index_exists?(TABLE_NAME, [:design_id, :note_id], unique: true, name: INDEX_NAME)

    add_concurrent_index TABLE_NAME, [:design_id, :note_id], unique: true, name: "#{INDEX_NAME}_int8"

    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      execute "DROP INDEX IF EXISTS #{INDEX_NAME}"
      rename_index TABLE_NAME, "#{INDEX_NAME}_int8", INDEX_NAME
    end
  end

  def down
    # no-op
  end
end
