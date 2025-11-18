# frozen_string_literal: true

class ValidateNotesSkNotNullConstraintAsync < Gitlab::Database::Migration[2.3]
  CONSTRAINT_NAME = 'check_82f260979e'

  milestone '18.6'

  def up
    prepare_async_check_constraint_validation :notes, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :notes, name: CONSTRAINT_NAME
  end
end
