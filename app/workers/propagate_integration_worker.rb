# frozen_string_literal: true

class PropagateIntegrationWorker
  include ApplicationWorker

  feature_category :integrations

  idempotent!

  def perform(integration_id, overwrite)
    Admin::PropagateIntegrationService.propagate(
      integration: Service.find(integration_id),
      overwrite: overwrite
    )
  end
end
