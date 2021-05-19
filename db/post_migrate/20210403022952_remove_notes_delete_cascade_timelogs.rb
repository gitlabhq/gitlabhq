# frozen_string_literal: true

class RemoveNotesDeleteCascadeTimelogs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CONSTRAINT_NAME = 'fk_timelogs_note_id'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :timelogs, :notes, column: :note_id, on_delete: :nullify, name: CONSTRAINT_NAME

    with_lock_retries do
      remove_foreign_key_if_exists :timelogs, :notes, column: :note_id, on_delete: :cascade
    end
  end

  def down
    add_concurrent_foreign_key :timelogs, :notes, column: :note_id, on_delete: :cascade

    with_lock_retries do
      remove_foreign_key_if_exists :timelogs, :notes, column: :note_id, on_delete: :nullify, name: CONSTRAINT_NAME
    end
  end
end
