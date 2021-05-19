# frozen_string_literal: true

class DestroyPagesDeploymentsWorker
  include ApplicationWorker

  idempotent!

  loggable_arguments 0, 1
  sidekiq_options retry: 3
  feature_category :pages
  tags :exclude_from_kubernetes

  def perform(project_id, last_deployment_id = nil)
    project = Project.find_by_id(project_id)

    return unless project

    ::Pages::DestroyDeploymentsService.new(project, last_deployment_id).execute
  end
end
