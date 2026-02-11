# frozen_string_literal: true

class AddNotNullConstraintToWebHookLogsDailyShardingKeys < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(
      :web_hook_logs_daily,
      :organization_id,
      :project_id,
      :group_id,
      validate: false
    )
  end

  def down
    remove_multi_column_not_null_constraint(
      :web_hook_logs_daily,
      :organization_id,
      :project_id,
      :group_id
    )
  end
end
