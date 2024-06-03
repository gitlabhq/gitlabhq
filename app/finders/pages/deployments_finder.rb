# frozen_string_literal: true

module Pages
  class DeploymentsFinder
    attr_reader :params

    def initialize(parent, params = {})
      @parent = parent
      @params = params
    end

    def execute
      deployments = PagesDeployment
      deployments = by_parent(deployments)
      deployments = by_active_status(deployments)
      deployments = find_versioned(deployments)
      sort(deployments)
    end

    private

    def by_parent(deployments)
      case @parent
      when Namespace then by_namespace(deployments)
      when Project then by_project(deployments)
      else raise "Pages::DeploymentsFinder only supports Namespace or Projects as parent"
      end
    end

    def by_project(deployments)
      deployments.project_id_in(@parent.id)
    end

    def by_namespace(deployments)
      deployments.project_id_in(@parent.projects.select(:id))
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
