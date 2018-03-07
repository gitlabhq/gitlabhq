class AddGroupBoardsIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    return if foreign_key_exists?(:boards, :group_id)

    add_concurrent_foreign_key :boards, :namespaces, column: :group_id, on_delete: :cascade

    add_concurrent_index :boards, :group_id
  end

  def down
    return unless foreign_key_exists?(:boards, :group_id)

    remove_foreign_key :boards, column: :group_id

    remove_concurrent_index :boards, :group_id
  end

  private

  def foreign_key_exists?(table, column)
    foreign_keys(table).any? do |key|
      key.options[:column] == column.to_s
    end
  end
end
