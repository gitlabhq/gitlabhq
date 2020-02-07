# frozen_string_literal: true

class RenameServicesTemplateToInstance < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_column_concurrently :services, :template, :instance
  end

  def down
    undo_rename_column_concurrently :services, :template, :instance
  end
end
