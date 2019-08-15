# frozen_string_literal: true

class RemoveIndexNotesOnNoteableType < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index(*index_arguments)
  end

  def down
    add_concurrent_index(*index_arguments)
  end

  private

  def index_arguments
    [
      :notes,
      [:noteable_type],
      {
        name: 'index_notes_on_noteable_type'
      }
    ]
  end
end
