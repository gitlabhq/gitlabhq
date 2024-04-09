# frozen_string_literal: true

class AddInternalToDraftNotes < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    add_column :draft_notes, :internal, :boolean, default: false, null: false
  end
end
