# frozen_string_literal: true

class AddProjectFkToObservabilityProjectO11ySettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.4'

  def up
    add_concurrent_foreign_key :observability_project_o11y_settings, :projects,
      column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :observability_project_o11y_settings, column: :project_id
    end
  end
end
