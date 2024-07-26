# frozen_string_literal: true

class AddShardingKeyColumnsToDeployTokens < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :deploy_tokens, :project_id, :bigint
    add_column :deploy_tokens, :group_id, :bigint
  end
end
