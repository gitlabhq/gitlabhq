# frozen_string_literal: true

class PropagateIntegrationGroupWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :integrations
  tags :exclude_from_kubernetes
  idempotent!

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(integration_id, min_id, max_id)
    integration = Integration.find_by_id(integration_id)
    return unless integration

    batch = if integration.instance_level?
              Group.where(id: min_id..max_id).without_integration(integration)
            else
              integration.group.descendants.where(id: min_id..max_id).without_integration(integration)
            end

    return if batch.empty?

    BulkCreateIntegrationService.new(integration, batch, 'group').execute
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
