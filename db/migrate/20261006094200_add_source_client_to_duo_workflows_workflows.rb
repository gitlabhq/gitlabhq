# frozen_string_literal: true

class AddSourceClientToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.6'

  TABLE = :duo_workflows_workflows

  def up
    with_lock_retries do
      add_column TABLE, :source_client_name, :text, null: true, if_not_exists: true
      add_column TABLE, :source_client_version, :text, null: true, if_not_exists: true
    end

    add_text_limit TABLE, :source_client_name, 64
    add_text_limit TABLE, :source_client_version, 64
  end

  def down
    with_lock_retries do
      remove_column TABLE, :source_client_name, if_exists: true
      remove_column TABLE, :source_client_version, if_exists: true
    end
  end
end
