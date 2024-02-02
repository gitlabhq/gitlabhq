# frozen_string_literal: true

class PropagateIntegrationInheritDescendantWorker
  include ApplicationWorker

  data_consistency :always
  sidekiq_options retry: 3
  feature_category :integrations
  urgency :low

  idempotent!

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(integration_id, min_id, max_id)
    integration = Integration.find_by_id(integration_id)
    return unless integration

    batch = Integration.inherited_descendants_from_self_or_ancestors_from(integration).where(id: min_id..max_id)

    Integrations::Propagation::BulkUpdateService.new(integration, batch).execute
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
