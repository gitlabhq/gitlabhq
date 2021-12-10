# frozen_string_literal: true

class CreateNamespacesSyncEvents < Gitlab::Database::Migration[1.0]
  def change
    create_table :namespaces_sync_events do |t|
      t.references :namespace, null: false, index: true, foreign_key: { on_delete: :cascade }
    end
  end
end
