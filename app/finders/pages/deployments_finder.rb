# frozen_string_literal: true

module Pages
  class DeploymentsFinder
    attr_reader :params

    def initialize(namespace, params = {})
      @namespace = namespace
      @params = params
    end

    def execute
      deployments = PagesDeployment
      deployments = by_namespace(deployments)
      deployments = by_active_status(deployments)
      deployments = find_versioned(deployments)
      sort(deployments)
    end

    private

    def by_namespace(deployments)
      deployments.project_id_in(@namespace.projects.select(:id))
    end

    def by_active_status(deployments)
      return deployments if params[:active].nil?

      params[:active] ? deployments.active : deployments.deactivated
    end

    def find_versioned(deployments)
      return deployments if params[:versioned].nil?

      params[:versioned] ? deployments.versioned : deployments.unversioned
    end

    def sort(deployments)
      deployments.order_by(params[:sort] || :created_desc)
    end
  end
end
