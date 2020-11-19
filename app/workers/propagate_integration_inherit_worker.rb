# frozen_string_literal: true

class PropagateIntegrationInheritWorker
  include ApplicationWorker

  feature_category :integrations
  idempotent!

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(integration_id, min_id, max_id)
    integration = Service.find_by_id(integration_id)
    return unless integration

    batch = Service.where(id: min_id..max_id).by_type(integration.type).inherit_from_id(integration.id)

    BulkUpdateIntegrationService.new(integration, batch).execute
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
