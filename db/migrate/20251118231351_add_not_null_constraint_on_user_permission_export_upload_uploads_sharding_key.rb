# frozen_string_literal: true

class AddNotNullConstraintOnUserPermissionExportUploadUploadsShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_not_null_constraint(:user_permission_export_upload_uploads, :uploaded_by_user_id)
  end

  def down
    remove_not_null_constraint(:user_permission_export_upload_uploads, :uploaded_by_user_id)
  end
end
