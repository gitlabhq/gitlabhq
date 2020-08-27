# frozen_string_literal: true

class PropagateIntegrationWorker
  include ApplicationWorker

  feature_category :integrations
  idempotent!
  loggable_arguments 1

  # Keep overwrite parameter for backwards compatibility.
  def perform(integration_id, overwrite = nil)
    Admin::PropagateIntegrationService.propagate(Service.find(integration_id))
  end
end
