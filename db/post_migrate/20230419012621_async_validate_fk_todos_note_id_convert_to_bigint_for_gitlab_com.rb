# frozen_string_literal: true

class AsyncValidateFkTodosNoteIdConvertToBigintForGitlabCom < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  TABLE_NAME = :todos
  COLUMN = :note_id_convert_to_bigint
  FK_NAME = :fk_todos_note_id_convert_to_bigint

  def up
    return unless should_run?

    prepare_async_foreign_key_validation TABLE_NAME, COLUMN, name: FK_NAME
  end

  def down
    return unless should_run?

    unprepare_async_foreign_key_validation TABLE_NAME, COLUMN, name: FK_NAME
  end

  private

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
