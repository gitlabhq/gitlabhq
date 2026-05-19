# frozen_string_literal: true

class AddMessagingCallbackContextToSiphonDuoWorkflowsWorkflows < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflows ADD COLUMN messaging_callback_context Nullable(String);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflows DROP COLUMN messaging_callback_context;
    SQL
  end
end
