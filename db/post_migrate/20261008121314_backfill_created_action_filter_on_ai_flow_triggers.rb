# frozen_string_literal: true

class BackfillCreatedActionFilterOnAiFlowTriggers < Gitlab::Database::Migration[2.4]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '19.5'

  FLOW_REFERENCES = %w[risk_classification/v1 recommend_reviewers/v1].freeze
  # Same filter as default_trigger_filter in both flow definitions.
  MERGE_REQUEST_FILTER = {
    'merge_request' => {
      'rules' => [
        { 'field' => 'action', 'operator' => 'in', 'value' => ['created'] }
      ]
    }
  }.freeze
  BATCH_SIZE = 1_000

  # These flows limit merge_request events to `created` through a precondition in code.
  # Store it on their triggers that have no merge_request filter, so the precondition can
  # be removed. A filter the customer set is left as it is. {6} is
  # Ai::FlowTrigger::EVENT_TYPES[:merge_request].
  def up
    item_ids = define_batchable_model('ai_catalog_items')
      .where(foundational_flow_reference: FLOW_REFERENCES)
      .pluck(:id)
    return if item_ids.empty?

    consumer_ids = define_batchable_model('ai_catalog_item_consumers')
      .where(ai_catalog_item_id: item_ids)
      .select(:id)

    # Batch over trigger ids: no consumers index serves the item filter in id order, so
    # batching over consumers reads every consumer of these flows for each batch boundary.
    define_batchable_model('ai_flow_triggers').each_batch(of: BATCH_SIZE) do |batch|
      batch
        .where("event_types @> '{6}'")
        .where("filter->'merge_request' IS NULL")
        .where(ai_catalog_item_consumer_id: consumer_ids)
        .update_all(["filter = filter || ?::jsonb", MERGE_REQUEST_FILTER.to_json])
    end
  end

  def down
    # no-op: the added filter matches what the precondition already enforced at runtime
  end
end
