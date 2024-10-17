# frozen_string_literal: true

class RenameComponentResourceTypeToComponentType < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.6'

  def up
    rename_column_concurrently :catalog_resource_components, :resource_type, :component_type
  end

  def down
    undo_rename_column_concurrently :catalog_resource_components, :resource_type, :component_type
  end
end
