# frozen_string_literal: true

class AddUniqueIndexDiffNoteIdConvertToBigintForGitlabCom < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = :note_diff_files
  INDEX_NAME = :index_note_diff_files_on_diff_note_id_convert_to_bigint

  def up
    return unless should_run?

    # This will replace the existing index_note_diff_files_on_diff_note_id
    add_concurrent_index TABLE_NAME, :diff_note_id_convert_to_bigint, unique: true,
      name: INDEX_NAME
  end

  def down
    return unless should_run?

    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  private

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
