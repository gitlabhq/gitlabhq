# frozen_string_literal: true

class AddIndexToUploadsOnUploadedByUserId < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'index_uploads_on_uploaded_by_user_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- large tables
    add_concurrent_index :uploads, :uploaded_by_user_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :uploads, INDEX_NAME
  end
end
