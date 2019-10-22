# frozen_string_literal: true

class RenameDesignManagementVersionUserToAuthor < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_column_concurrently :design_management_versions, :user_id, :author_id
  end

  def down
    undo_rename_column_concurrently :design_management_versions, :user_id, :author_id
  end
end
