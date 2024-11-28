# frozen_string_literal: true

class AddImportedToResourceEventTables < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :resource_state_events, :imported, :integer, default: 0, null: false, limit: 2
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :resource_label_events, :imported, :integer, default: 0, null: false, limit: 2
    # rubocop:enable Migration/PreventAddingColumns
    add_column :resource_milestone_events, :imported, :integer, default: 0, null: false, limit: 2
  end
end
