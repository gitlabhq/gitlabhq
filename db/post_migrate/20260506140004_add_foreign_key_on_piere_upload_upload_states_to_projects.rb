# frozen_string_literal: true

class AddForeignKeyOnPiereUploadUploadStatesToProjects < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  def up
    add_concurrent_foreign_key :project_import_export_relation_export_upload_upload_states,
      :projects,
      column: :project_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :project_import_export_relation_export_upload_upload_states, column: :project_id
    end
  end
end
