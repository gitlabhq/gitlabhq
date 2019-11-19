# frozen_string_literal: true

class CleanupDesignManagementVersionUserToAuthorRename < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :design_management_versions, :user_id, :author_id
  end

  def down
    undo_cleanup_concurrent_column_rename :design_management_versions, :user_id, :author_id
  end
end
