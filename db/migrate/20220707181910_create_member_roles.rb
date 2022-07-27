# frozen_string_literal: true

class CreateMemberRoles < Gitlab::Database::Migration[2.0]
  def change
    create_table :member_roles do |t|
      t.references :namespace,
                   index: true,
                   null: false,
                   foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.integer :base_access_level, null: false
      t.boolean :download_code, default: false
    end
  end
end
