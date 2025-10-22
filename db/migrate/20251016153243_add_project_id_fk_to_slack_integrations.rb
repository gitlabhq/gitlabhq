# frozen_string_literal: true

class AddProjectIdFkToSlackIntegrations < Gitlab::Database::Migration[2.3]
  TABLE_NAME = :slack_integrations
  RELATED_TABLE = :projects
  COLUMN_NAME = :project_id

  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_concurrent_foreign_key(
      TABLE_NAME,
      RELATED_TABLE,
      column: COLUMN_NAME,
      on_delete: :cascade
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        TABLE_NAME,
        column: COLUMN_NAME,
        on_delete: :cascade
      )
    end
  end
end
