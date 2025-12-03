# frozen_string_literal: true

class CreateUserSavedViews < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    create_table :user_saved_views do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.bigint :saved_view_id, null: false, index: true
      t.bigint :namespace_id, null: false, index: false
      t.integer :relative_position, index: true

      t.index [:user_id, :saved_view_id], unique: true
      t.index [:namespace_id, :user_id], name: 'index_user_saved_views_on_namespace_and_user'
    end
  end
end
