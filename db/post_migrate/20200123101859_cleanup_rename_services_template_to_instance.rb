# frozen_string_literal: true

class CleanupRenameServicesTemplateToInstance < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :services, :template, :instance
  end

  def down
    undo_cleanup_concurrent_column_rename :services, :template, :instance
  end
end
