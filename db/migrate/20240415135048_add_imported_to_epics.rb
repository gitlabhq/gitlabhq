# frozen_string_literal: true

class AddImportedToEpics < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :epics, :imported, :integer, default: 0, null: false, limit: 2
  end
end
