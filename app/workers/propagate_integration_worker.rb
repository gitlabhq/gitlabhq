# frozen_string_literal: true

class PropagateIntegrationWorker
  include ApplicationWorker

  data_consistency :always
  sidekiq_options retry: 3
  feature_category :integrations
  loggable_arguments 1
  urgency :low

  idempotent!

  def perform(integration_id)
    integration = Integration.find_by_id(integration_id)
    return unless integration
    return if integration.project_level?

    ::Integrations::PropagateService.new(integration).execute
  end
end
