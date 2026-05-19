# frozen_string_literal: true

class AddAiCatalogRestrictedToGroupHierarchyToNamespaceAiSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    add_column :namespace_ai_settings, :ai_catalog_restricted_to_group_hierarchy, :boolean, default: false,
      null: false
  end

  def down
    remove_column :namespace_ai_settings, :ai_catalog_restricted_to_group_hierarchy
  end
end
