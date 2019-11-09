# frozen_string_literal: true

class AddMarkForDeletionIndicesToNamespaces < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :namespaces, :users, column: :marked_for_deletion_by_user_id, on_delete: :nullify
    add_concurrent_index :namespaces, :marked_for_deletion_by_user_id, where: 'marked_for_deletion_by_user_id IS NOT NULL'
    add_concurrent_index :namespaces, :marked_for_deletion_at, where: 'marked_for_deletion_at IS NOT NULL'
  end

  def down
    remove_foreign_key_if_exists :namespaces, column: :marked_for_deletion_by_user_id
    remove_concurrent_index :namespaces, :marked_for_deletion_by_user_id
    remove_concurrent_index :namespaces, :marked_for_deletion_at
  end
end
