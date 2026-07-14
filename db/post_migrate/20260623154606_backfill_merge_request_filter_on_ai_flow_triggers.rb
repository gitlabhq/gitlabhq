# frozen_string_literal: true

class BackfillMergeRequestFilterOnAiFlowTriggers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '19.2'

  MERGE_REQUEST_FILTER = '{"merge_request": {"rules": [{"field": "action", "operator": "in", "value": ["approved"]}]}}'
  BATCH_SIZE = 10_000

  def up
    # event_type {6} maps to Ai::FlowTrigger::EVENT_TYPES[6] (merge_request)
    # in ee/app/models/ai/flow_trigger.rb
    # merge_request triggers default to 'approved' (the only GA action at the time)
    # Idempotent: the filter = '{}' guard ensures re-runs
    # won't overwrite filters set after deploy
    define_batchable_model('ai_flow_triggers').each_batch(of: BATCH_SIZE) do |batch|
      batch
        .where("event_types @> '{6}'")
        .where("filter = '{}'::jsonb")
        .update_all("filter = '#{MERGE_REQUEST_FILTER}'::jsonb")
    end
  end

  def down
    # no-op
  end
end
