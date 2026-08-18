# frozen_string_literal: true

class CreateMergeRequestSavedViews < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    create_table :merge_request_saved_views do |t|
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.text :name, null: false, limit: 255
      t.jsonb :filters, null: false, default: {}

      t.index [:user_id, :name], unique: true
    end
  end
end
