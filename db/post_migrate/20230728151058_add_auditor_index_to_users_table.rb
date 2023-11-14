# frozen_string_literal: true

class AddAuditorIndexToUsersTable < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_users_for_auditors'
  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/PreventIndexCreation
    add_concurrent_index :users, :id, where: 'auditor IS true', name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :users, name: INDEX_NAME
  end
end
