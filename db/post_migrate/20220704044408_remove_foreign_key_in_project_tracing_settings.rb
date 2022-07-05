# frozen_string_literal: true

class RemoveForeignKeyInProjectTracingSettings < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:project_tracing_settings, column: :project_id)
    end
  end

  def down
    add_concurrent_foreign_key :project_tracing_settings, :projects,
      column: :project_id, on_delete: :cascade, name: 'fk_rails_fe56f57fc6'
  end
end
