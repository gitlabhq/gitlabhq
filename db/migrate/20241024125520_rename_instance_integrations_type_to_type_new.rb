# frozen_string_literal: true

class RenameInstanceIntegrationsTypeToTypeNew < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  def up
    rename_column_concurrently :instance_integrations, :type, :type_new
  end

  def down
    undo_rename_column_concurrently :instance_integrations, :type, :type_new
  end
end
