# frozen_string_literal: true

class AddReassignmentTokenToImportSourceUsers < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  def up
    add_column :import_source_users, :reassignment_token, :text
    add_concurrent_index :import_source_users, :reassignment_token, unique: true
    add_text_limit :import_source_users, :reassignment_token, 32
  end

  def down
    remove_column :import_source_users, :reassignment_token, :text
  end
end
