# frozen_string_literal: true

class RemoveMergeRequestEventFromDeveloperAiFlowTriggers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '19.5'

  # Two code paths auto-create Developer triggers with different descriptions:
  #   - ItemConsumers::CreateService (project creation): "Auto-created triggers for Developer"
  #   - SyncFoundationalFlowsService (re-sync/inherited): "Foundational flow trigger for Developer"
  # Both use an empty filter; user-created triggers carry a caller-provided description.
  AUTO_CREATED_DESCRIPTIONS = [
    'Foundational flow trigger for Developer',
    'Auto-created triggers for Developer'
  ].freeze
  DEVELOPER_FLOW_REFERENCE = 'developer/v1'
  CONSUMER_BATCH_SIZE = 1_000

  # Foundational-flow trigger sync is create-only, so Developer triggers synced while the
  # flow's defaults included merge_request keep the stale event
  # (https://gitlab.com/gitlab-org/gitlab/-/issues/628094). {6} is
  # Ai::FlowTrigger::EVENT_TYPES[:merge_request]. User-created triggers are kept: they
  # carry a caller-provided description or a filter, unlike the auto-created signature.
  #
  # Batches are driven from the consumer side (ai_catalog_item_consumers filtered to
  # developer/v1 items) so only relevant triggers are touched and per-statement time
  # stays within the 100ms guideline.
  def up
    developer_item_ids = developer_catalog_item_ids
    return if developer_item_ids.empty?

    define_batchable_model('ai_catalog_item_consumers')
      .where(ai_catalog_item_id: developer_item_ids)
      .each_batch(of: CONSUMER_BATCH_SIZE) do |consumer_batch|
        consumer_ids = consumer_batch.pluck(:id)

        stale_triggers = define_batchable_model('ai_flow_triggers')
          .where(ai_catalog_item_consumer_id: consumer_ids)
          .where("event_types @> '{6}'")
          .where(description: AUTO_CREATED_DESCRIPTIONS)
          .where("filter = '{}'::jsonb")

        stale_triggers.where("cardinality(event_types) = 1").delete_all
        stale_triggers.where("cardinality(event_types) > 1")
          .update_all("event_types = array_remove(event_types, 6::smallint)")
      end
  end

  def down
    # no-op: removed merge_request events cannot be told apart from intentionally
    # configured ones, so the cleanup is not reversible
  end

  private

  def developer_catalog_item_ids
    define_batchable_model('ai_catalog_items')
      .where(foundational_flow_reference: DEVELOPER_FLOW_REFERENCE)
      .pluck(:id)
  end
end
