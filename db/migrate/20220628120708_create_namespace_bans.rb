# frozen_string_literal: true

class CreateNamespaceBans < Gitlab::Database::Migration[2.0]
  UNIQUE_INDEX_NAME = 'index_namespace_bans_on_namespace_id_and_user_id'

  def change
    create_table :namespace_bans do |t|
      t.bigint :namespace_id, null: false
      t.bigint :user_id, null: false, index: true
      t.timestamps_with_timezone

      t.index [:namespace_id, :user_id], unique: true, name: UNIQUE_INDEX_NAME
    end
  end
end
