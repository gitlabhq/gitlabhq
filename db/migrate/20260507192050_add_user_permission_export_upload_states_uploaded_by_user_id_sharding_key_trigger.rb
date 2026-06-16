# frozen_string_literal: true

class AddUserPermissionExportUploadStatesUploadedByUserIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :user_permission_export_upload_upload_states,
      sharding_key: :uploaded_by_user_id,
      parent_table: :user_permission_export_upload_uploads,
      parent_sharding_key: :uploaded_by_user_id,
      foreign_key: :user_permission_export_upload_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :user_permission_export_upload_upload_states,
      sharding_key: :uploaded_by_user_id,
      parent_table: :user_permission_export_upload_uploads,
      parent_sharding_key: :uploaded_by_user_id,
      foreign_key: :user_permission_export_upload_upload_id
    )
  end
end
