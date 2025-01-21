# frozen_string_literal: true

class AddIndexReassignToImportSourceUserPlaceholderReferences < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  INDEX_NAME = 'idx_import_source_user_placeholder_references_on_user_model_id'

  DUPLICATED_INDEX = 'index_import_source_user_placeholder_references_on_source_user_'

  def up
    add_concurrent_index :import_source_user_placeholder_references,
      [:source_user_id, :model, :user_reference_column, :alias_version, :id], name: INDEX_NAME
    remove_concurrent_index_by_name :import_source_user_placeholder_references, DUPLICATED_INDEX
  end

  def down
    add_concurrent_index :import_source_user_placeholder_references, [:source_user_id], name: DUPLICATED_INDEX
    remove_concurrent_index_by_name :import_source_user_placeholder_references, INDEX_NAME
  end
end
