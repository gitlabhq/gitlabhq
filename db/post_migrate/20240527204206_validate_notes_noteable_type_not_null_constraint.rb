# frozen_string_literal: true

class ValidateNotesNoteableTypeNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    validate_not_null_constraint :notes, :noteable_type
  end

  def down
    # no-op
  end
end
