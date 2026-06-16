# frozen_string_literal: true

class AddDependencyListExportUploadStatesNamespaceIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :dependency_list_export_upload_states,
      sharding_key: :namespace_id,
      parent_table: :dependency_list_export_uploads,
      parent_sharding_key: :namespace_id,
      foreign_key: :dependency_list_export_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :dependency_list_export_upload_states,
      sharding_key: :namespace_id,
      parent_table: :dependency_list_export_uploads,
      parent_sharding_key: :namespace_id,
      foreign_key: :dependency_list_export_upload_id
    )
  end
end
