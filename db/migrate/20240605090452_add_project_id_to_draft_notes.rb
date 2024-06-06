# frozen_string_literal: true

class AddProjectIdToDraftNotes < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :draft_notes, :project_id, :bigint
  end
end
