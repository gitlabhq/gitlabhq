# frozen_string_literal: true

class PropagateIntegrationGroupWorker
  include ApplicationWorker

  feature_category :integrations
  idempotent!

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(integration_id, min_id, max_id)
    integration = Service.find_by_id(integration_id)
    return unless integration

    batch = Group.where(id: min_id..max_id).without_integration(integration)

    BulkCreateIntegrationService.new(integration, batch, 'group').execute
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
