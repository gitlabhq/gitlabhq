# frozen_string_literal: true

class AddShardingKeyCheckConstraintToWebHooks < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(
      :web_hooks,
      :project_id,
      :group_id,
      :organization_id
    )
  end

  def down
    remove_multi_column_not_null_constraint(
      :web_hooks,
      :project_id,
      :group_id,
      :organization_id
    )
  end
end
