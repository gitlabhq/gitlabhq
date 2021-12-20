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
    ::Integrations::PropagateService.propagate(Integration.find(integration_id))
  end
end
