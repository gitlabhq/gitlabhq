# frozen_string_literal: true

class AddYamlDefinitionFileToAiCatalogItemVersions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.11'

  def up
    with_lock_retries do
      add_column :ai_catalog_item_versions, :yaml_definition_file, :text
      add_column :ai_catalog_item_versions, :yaml_definition_file_store, :smallint, default: 1, null: false
    end

    add_text_limit :ai_catalog_item_versions, :yaml_definition_file, 255
  end

  def down
    with_lock_retries do
      remove_column :ai_catalog_item_versions, :yaml_definition_file
      remove_column :ai_catalog_item_versions, :yaml_definition_file_store
    end
  end
end
