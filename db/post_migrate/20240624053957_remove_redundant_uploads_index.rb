# frozen_string_literal: true

class RemoveRedundantUploadsIndex < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'index_uploads_on_model_id_and_model_type'

  def up
    remove_concurrent_index_by_name :uploads, INDEX_NAME
  end

  def down
    add_concurrent_index :uploads, [:model_id, :model_type], name: INDEX_NAME
  end
end
