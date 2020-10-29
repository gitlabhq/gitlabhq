# frozen_string_literal: true

module Pages
  class DestroyDeploymentsService
    def initialize(project, last_deployment_id = nil)
      @project = project
      @last_deployment_id = last_deployment_id
    end

    def execute
      deployments_to_destroy = @project.pages_deployments
      deployments_to_destroy = deployments_to_destroy.older_than(@last_deployment_id) if @last_deployment_id
      deployments_to_destroy.find_each(&:destroy) # rubocop: disable CodeReuse/ActiveRecord
    end
  end
end
