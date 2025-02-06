# frozen_string_literal: true

class PrepareDraftNotesProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  CONSTRAINT_NAME = :check_2a752d05fe

  def up
    prepare_async_check_constraint_validation :draft_notes, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :draft_notes, name: CONSTRAINT_NAME
  end
end
