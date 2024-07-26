# frozen_string_literal: true

class AddShardingKeyForeignKeysToDeployTokens < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  def up
    add_concurrent_foreign_key :deploy_tokens, :projects, column: :project_id
    add_concurrent_foreign_key :deploy_tokens, :namespaces, column: :group_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :deploy_tokens, column: :project_id
    end

    with_lock_retries do
      remove_foreign_key :deploy_tokens, column: :group_id
    end
  end
end
