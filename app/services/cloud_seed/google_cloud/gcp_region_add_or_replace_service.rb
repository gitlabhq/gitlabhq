# frozen_string_literal: true

module CloudSeed
  module GoogleCloud
    class GcpRegionAddOrReplaceService < ::CloudSeed::GoogleCloud::BaseService
      def execute(environment, region)
        gcp_region_key = Projects::GoogleCloud::GcpRegionsController::GCP_REGION_CI_VAR_KEY

        change_params = { variable_params: { key: gcp_region_key, value: region, environment_scope: environment } }
        filter_params = { key: gcp_region_key, filter: { environment_scope: environment } }

        existing_variable = ::Ci::VariablesFinder.new(project, filter_params).execute.first

        if existing_variable
          change_params[:action] = :update
          change_params[:variable] = existing_variable
        else
          change_params[:action] = :create
        end

        ::Ci::ChangeVariableService.new(container: project, current_user: current_user, params: change_params).execute
      end
    end
  end
end
