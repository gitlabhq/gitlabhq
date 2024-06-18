# frozen_string_literal: true

class AsyncValidateNotesNoteableTypeNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  CONSTRAINT_NAME = 'check_1244cbd7d0'

  def up
    prepare_async_check_constraint_validation :notes, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :notes, name: CONSTRAINT_NAME
  end
end
