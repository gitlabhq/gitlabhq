# frozen_string_literal: true

class AddGroupColumnToEvents < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column(:events, :group_id, :bigint) unless column_exists?(:events, :group_id)
    add_concurrent_index(:events, :group_id)
    add_concurrent_foreign_key(:events, :namespaces, column: :group_id, on_delete: :cascade)
  end

  def down
    remove_column(:events, :group_id) if column_exists?(:events, :group_id)
  end
end
