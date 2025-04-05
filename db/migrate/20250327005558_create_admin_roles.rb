# frozen_string_literal: true

class CreateAdminRoles < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def up
    create_table :admin_roles do |t|
      t.text :name, null: false, limit: 255
      t.text :description, limit: 255
      t.jsonb :permissions, null: false, default: {}

      t.timestamps_with_timezone null: false
    end

    add_index :admin_roles, :name, unique: true
  end

  def down
    drop_table :admin_roles, if_exists: true
  end
end
