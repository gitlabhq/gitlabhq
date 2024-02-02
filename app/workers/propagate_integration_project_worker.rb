# frozen_string_literal: true

class PropagateIntegrationProjectWorker
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

    batch = Project.where(id: min_id..max_id).without_integration(integration)
    batch = batch.in_namespace(integration.group.self_and_descendants) if integration.group_level?

    return if batch.empty?

    Integrations::Propagation::BulkCreateService.new(integration, batch, 'project').execute
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
