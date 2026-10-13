# frozen_string_literal: true

# Ai::DuoWorkflows::FlowCallbackHook is being removed in the same release. Rows
# of that type can never receive deliveries (no delivery path was ever wired
# up), but once the class is gone, loading one raises
# ActiveRecord::SubclassNotFound, so remove them together with their logs.
class RemoveDuoFlowCallbackHooksFromWebHooks < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '19.5'

  BATCH_SIZE = 1000
  LEGACY_HOOK_TYPE = 'Ai::DuoWorkflows::FlowCallbackHook'

  class WebHook < MigrationRecord
    include EachBatch

    self.table_name = 'web_hooks'
  end

  class WebHookLog < MigrationRecord
    self.table_name = 'web_hook_logs_daily'
  end

  def up
    WebHook.where(type: LEGACY_HOOK_TYPE).each_batch(of: BATCH_SIZE, column: :id) do |hooks|
      WebHookLog.where(web_hook_id: hooks.select(:id)).delete_all
      hooks.delete_all
    end
  end

  def down
    # no-op: deleted registrations cannot be restored
  end
end
