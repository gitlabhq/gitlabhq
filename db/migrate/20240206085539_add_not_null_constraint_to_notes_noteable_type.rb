# frozen_string_literal: true

class AddNotNullConstraintToNotesNoteableType < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  def up
    add_not_null_constraint :notes, :noteable_type, validate: false
  end

  def down
    remove_not_null_constraint :notes, :noteable_type
  end
end
