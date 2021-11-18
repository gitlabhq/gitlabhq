# frozen_string_literal: true

class RemoveForeignKeysFromOpenProjectDataTable < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key :open_project_tracker_data, column: :service_id
    end
  end

  def down
    with_lock_retries do
      add_foreign_key :open_project_tracker_data, :integrations, column: :service_id, on_delete: :cascade
    end
  end
end
