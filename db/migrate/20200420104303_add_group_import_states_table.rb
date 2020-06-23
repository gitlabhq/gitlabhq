# frozen_string_literal: true

class AddGroupImportStatesTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  def up
    with_lock_retries do
      create_table :group_import_states, id: false do |t|
        t.references :group, primary_key: true, foreign_key: { to_table: :namespaces, on_delete: :cascade }
        t.timestamps_with_timezone null: false
        t.integer :status, limit: 2, null: false, default: 0
        t.text :jid, null: false, unique: true
        t.text :last_error
      end
    end
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    drop_table :group_import_states
  end
end
