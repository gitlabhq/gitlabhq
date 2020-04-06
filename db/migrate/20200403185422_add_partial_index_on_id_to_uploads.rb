# frozen_string_literal: true

class AddPartialIndexOnIdToUploads < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_uploads_store_is_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index :uploads, :id, where: 'store IS NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :uploads, INDEX_NAME
  end
end
