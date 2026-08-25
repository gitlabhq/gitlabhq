# frozen_string_literal: true

class AddSourceTypeAndSourceLinkToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  TABLE = :duo_workflows_workflows

  def up
    with_lock_retries do
      add_column TABLE, :source_type, :smallint, null: true, if_not_exists: true
      add_column TABLE, :source_link, :text, null: true, if_not_exists: true
    end

    add_text_limit TABLE, :source_link, 2_048
  end

  def down
    with_lock_retries do
      remove_column TABLE, :source_type, if_exists: true
      remove_column TABLE, :source_link, if_exists: true
    end
  end
end
