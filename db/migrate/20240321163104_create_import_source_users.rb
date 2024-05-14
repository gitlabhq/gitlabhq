# frozen_string_literal: true

class CreateImportSourceUsers < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    create_table :import_source_users do |t|
      t.references :placeholder_user, index: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :reassign_to_user, index: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :namespace, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.integer :status, null: false, limit: 2, default: 0
      t.text :source_username, limit: 255
      t.text :source_name, limit: 255
      t.text :source_user_identifier, null: false, limit: 255
      t.text :source_hostname, null: false, limit: 255
      t.text :import_type, null: false, limit: 255
    end

    add_index(:import_source_users,
      %i[source_user_identifier namespace_id source_hostname import_type],
      unique: true,
      name: 'unique_import_source_users_source_identifier_and_import_source'
    )
  end
end
