# frozen_string_literal: true

class AddListsShardingKeyNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_multi_column_not_null_constraint(:lists, :group_id, :project_id, validate: false)
  end

  def down
    remove_multi_column_not_null_constraint(:lists, :group_id, :project_id)
  end
end
