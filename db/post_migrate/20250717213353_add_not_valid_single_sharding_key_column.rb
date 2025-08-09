# frozen_string_literal: true

class AddNotValidSingleShardingKeyColumn < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_multi_column_not_null_constraint(
      :labels,
      :project_id,
      :group_id,
      :organization_id,
      validate: false
    )
  end

  def down
    remove_multi_column_not_null_constraint(:labels, :project_id, :group_id, :organization_id)
  end
end
