# frozen_string_literal: true

class RemoveInvalidWebhookRecords < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    WebHook.where(
      project_id: nil,
      group_id: nil,
      organization_id: nil,
      integration_id: nil
    ).delete_all
  end

  def down
    # no op
  end
end
