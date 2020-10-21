# frozen_string_literal: true

class PropagateIntegrationWorker
  include ApplicationWorker

  feature_category :integrations
  idempotent!
  loggable_arguments 1

  # TODO: Keep overwrite parameter for backwards compatibility. Remove after >= 14.0
  # https://gitlab.com/gitlab-org/gitlab/-/issues/255382
  def perform(integration_id, overwrite = nil)
    Admin::PropagateIntegrationService.propagate(Service.find(integration_id))
  end
end
