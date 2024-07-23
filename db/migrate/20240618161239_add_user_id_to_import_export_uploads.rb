# frozen_string_literal: true

class AddUserIdToImportExportUploads < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  disable_ddl_transaction!

  INDEX_NAME = :index_import_export_uploads_on_user_id

  def up
    with_lock_retries do
      add_column :import_export_uploads, :user_id, :bigint, null: true
    end

    add_concurrent_index :import_export_uploads, :user_id, name: INDEX_NAME

    add_concurrent_foreign_key :import_export_uploads, :users, column: :user_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :import_export_uploads, column: :user_id
    end

    remove_concurrent_index_by_name :import_export_uploads, INDEX_NAME

    with_lock_retries do
      remove_column :import_export_uploads, :user_id
    end
  end
end
