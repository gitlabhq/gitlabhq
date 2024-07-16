# frozen_string_literal: true

class ExtendUploadsIndex < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'index_uploads_on_model_id_model_type_uploader_created_at'

  def up
    add_concurrent_index :uploads, [:model_id, :model_type, :uploader, :created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :uploads, INDEX_NAME
  end
end
