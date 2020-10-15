# frozen_string_literal: true

class AddProjectForeignKeyToBulkImportEntities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :bulk_import_entities, :projects, column: :project_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :bulk_import_entities, column: :project_id
    end
  end
end
