# frozen_string_literal: true

class AddIndexNotesOnProjectIdAndIdAndSystemFalse < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(*index_arguments)
  end

  def down
    remove_concurrent_index(*index_arguments)
  end

  private

  def index_arguments
    [
      :notes,
      [:project_id, :id],
      {
        name: 'index_notes_on_project_id_and_id_and_system_false',
        where: 'NOT system'
      }
    ]
  end
end
