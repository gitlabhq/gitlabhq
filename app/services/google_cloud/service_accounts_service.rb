# frozen_string_literal: true

module GoogleCloud
  ##
  # GCP keys used to store Google Cloud Service Accounts
  GCP_KEYS = %w[GCP_PROJECT_ID GCP_SERVICE_ACCOUNT GCP_SERVICE_ACCOUNT_KEY].freeze

  ##
  # This service deals with GCP Service Accounts in GitLab

  class ServiceAccountsService < ::BaseService
    ##
    # Find GCP Service Accounts in a GitLab project
    #
    # This method looks up GitLab project's CI vars
    # and returns Google Cloud Service Accounts combinations
    # aligning GitLab project and ref to GCP projects

    def find_for_project
      group_vars_by_ref.map do |environment_scope, value|
        {
          ref: environment_scope,
          gcp_project: value['GCP_PROJECT_ID'],
          service_account_exists: value['GCP_SERVICE_ACCOUNT'].present?,
          service_account_key_exists: value['GCP_SERVICE_ACCOUNT_KEY'].present?
        }
      end
    end

    def add_for_project(ref, gcp_project_id, service_account, service_account_key, is_protected)
      project_var_create_or_replace(
        ref,
        'GCP_PROJECT_ID',
        gcp_project_id,
        is_protected
      )
      project_var_create_or_replace(
        ref,
        'GCP_SERVICE_ACCOUNT',
        service_account,
        is_protected
      )
      project_var_create_or_replace(
        ref,
        'GCP_SERVICE_ACCOUNT_KEY',
        service_account_key,
        is_protected
      )
    end

    private

    def group_vars_by_ref
      filtered_vars = project.variables.filter { |variable| GCP_KEYS.include? variable.key }
      filtered_vars.each_with_object({}) do |variable, grouped|
        grouped[variable.environment_scope] ||= {}
        grouped[variable.environment_scope][variable.key] = variable.value
      end
    end

    def project_var_create_or_replace(environment_scope, key, value, is_protected)
      change_params = { variable_params: { key: key, value: value, environment_scope: environment_scope, protected: is_protected } }
      filter_params = { key: key, filter: { environment_scope: environment_scope } }

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
