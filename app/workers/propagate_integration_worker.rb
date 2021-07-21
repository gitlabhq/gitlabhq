# frozen_string_literal: true

class PropagateIntegrationWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :integrations
  idempotent!
  loggable_arguments 1

  def perform(integration_id)
    Admin::PropagateIntegrationService.propagate(Integration.find(integration_id))
  end
end
