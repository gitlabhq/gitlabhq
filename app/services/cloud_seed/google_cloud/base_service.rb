# frozen_string_literal: true

module CloudSeed
  module GoogleCloud
    class BaseService < ::BaseService
      protected

      def google_oauth2_token
        @params[:google_oauth2_token]
      end

      def gcp_project_id
        @params[:gcp_project_id]
      end

      def environment_name
        @params[:environment_name]
      end

      def google_api_client
        @google_api_client_instance ||= GoogleApi::CloudPlatform::Client.new(google_oauth2_token, nil)
      end

      def unique_gcp_project_ids
        filter_params = { key: 'GCP_PROJECT_ID' }
        @unique_gcp_project_ids ||= ::Ci::VariablesFinder.new(project, filter_params).execute.map(&:value).uniq
      end

      def group_vars_by_environment(keys)
        filtered_vars = project.variables.filter { |variable| keys.include? variable.key }
        filtered_vars.each_with_object({}) do |variable, grouped|
          grouped[variable.environment_scope] ||= {}
          grouped[variable.environment_scope][variable.key] = variable.value
        end
      end

      def create_or_replace_project_vars(environment_scope, key, value, is_protected, is_masked = false)
        change_params = {
          variable_params: {
            key: key,
            value: value,
            environment_scope: environment_scope,
            protected: is_protected,
            masked: is_masked
          }
        }
        existing_variable = find_existing_variable(environment_scope, key)

        if existing_variable
          change_params[:action] = :update
          change_params[:variable] = existing_variable
        else
          change_params[:action] = :create
        end

        ::Ci::ChangeVariableService.new(container: project, current_user: current_user, params: change_params).execute
      end

      private

      def find_existing_variable(environment_scope, key)
        filter_params = { key: key, filter: { environment_scope: environment_scope } }
        ::Ci::VariablesFinder.new(project, filter_params).execute.first
      end
    end
  end
end
