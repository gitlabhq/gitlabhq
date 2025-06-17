# frozen_string_literal: true

class IndexNamespaceSettingsNamespaceIdWhereArchivedTrue < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  INDEX_NAME = 'index_namespace_settings_on_namespace_id_where_archived_true'

  def up
    add_concurrent_index(
      :namespace_settings,
      :namespace_id,
      name: INDEX_NAME,
      where: 'archived = true'
    )
  end

  def down
    remove_concurrent_index_by_name :namespace_settings, name: INDEX_NAME
  end
end
