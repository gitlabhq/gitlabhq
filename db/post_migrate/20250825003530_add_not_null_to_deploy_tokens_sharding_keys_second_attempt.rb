# frozen_string_literal: true

class AddNotNullToDeployTokensShardingKeysSecondAttempt < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_multi_column_not_null_constraint :deploy_tokens, :project_id, :group_id
  end

  def down
    remove_multi_column_not_null_constraint :deploy_tokens, :project_id, :group_id
  end
end
