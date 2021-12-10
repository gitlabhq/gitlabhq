# frozen_string_literal: true

class CreateProjectsSyncEvents < Gitlab::Database::Migration[1.0]
  def change
    create_table :projects_sync_events do |t|
      t.references :project, null: false, index: true, foreign_key: { on_delete: :cascade }
    end
  end
end
