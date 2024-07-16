# frozen_string_literal: true

class SyncGroupMergeRequestSettings < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!
  milestone '17.2'

  def up
    execute <<~SQL
    UPDATE group_merge_request_approval_settings
    SET require_reauthentication_to_approve = true
    WHERE require_password_to_approve = true;
    SQL
  end

  def down
    # no-op

    # Comment explaining why changes performed by `up` cannot be reversed:
    # Data changes are being performed
  end
end
