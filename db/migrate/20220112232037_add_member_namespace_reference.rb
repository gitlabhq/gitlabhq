# frozen_string_literal: true

class AddMemberNamespaceReference < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    add_column :members, :member_namespace_id, :bigint unless column_exists?(:members, :member_namespace_id)
  end

  def down
    remove_column :members, :member_namespace_id if column_exists?(:members, :member_namespace_id)
  end
end
