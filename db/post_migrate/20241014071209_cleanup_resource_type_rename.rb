# frozen_string_literal: true

class CleanupResourceTypeRename < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.6'

  def up
    cleanup_concurrent_column_rename :catalog_resource_components, :resource_type, :component_type
  end

  def down
    undo_cleanup_concurrent_column_rename :catalog_resource_components, :resource_type, :component_type
  end
end
