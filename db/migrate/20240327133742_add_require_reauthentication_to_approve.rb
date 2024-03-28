# frozen_string_literal: true

class AddRequireReauthenticationToApprove < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  COLUMN_NAME = 'require_reauthentication_to_approve'

  def up
    add_column :project_settings, COLUMN_NAME, :boolean
    add_column :group_merge_request_approval_settings, COLUMN_NAME, :boolean, default: false, null: false
  end

  def down
    remove_column :project_settings, COLUMN_NAME, if_exists: true
    remove_column :group_merge_request_approval_settings, COLUMN_NAME, if_exists: true
  end
end
