# frozen_string_literal: true

class BackfillWorkItemFilterOnAiFlowTriggers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  WORK_ITEM_FILTER = '{"work_item": {"rules": [{"field": "action", "operator": "in", "value": ["created"]}]}}'
  BATCH_SIZE = 10_000

  def up
    # event_type {7} maps to Ai::FlowTrigger::EVENT_TYPES[7] (work_item)
    # in ee/app/models/ai/flow_trigger.rb
    # work_item triggers default to 'created' (the only GA action at the time)
    # Idempotent: the filter = '{}' guard ensures re-runs won't overwrite filters set after deploy.
    define_batchable_model('ai_flow_triggers').each_batch(of: BATCH_SIZE) do |batch|
      batch
        .where("event_types @> '{7}'")
        .where("filter = '{}'::jsonb")
        .update_all("filter = '#{WORK_ITEM_FILTER}'::jsonb")
    end
  end

  def down
    # no-op
  end
end
