# frozen_string_literal: true

class CreateUserPermissionExportUploads < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      unless table_exists?(:user_permission_export_uploads)
        create_table :user_permission_export_uploads do |t|
          t.timestamps_with_timezone null: false
          t.references :user, foreign_key: { on_delete: :cascade }, index: false, null: false
          t.integer :file_store
          t.integer :status, limit: 2, null: false, default: 0
          t.text :file

          t.index [:user_id, :status]
        end
      end
    end

    add_text_limit :user_permission_export_uploads, :file, 255
  end

  def down
    with_lock_retries do
      drop_table :user_permission_export_uploads
    end
  end
end
