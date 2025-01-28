# frozen_string_literal: true

module API
  module Ci
    class Variables < ::API::Base
      include PaginationParams

      before { authenticate! }
      before { authorize! :admin_cicd_variables, user_project }

      feature_category :ci_variables

      helpers ::API::Helpers::VariablesHelpers

      params do
        requires :id, types: [String, Integer], desc: 'The ID of a project or URL-encoded NAMESPACE/PROJECT_NAME of the project owned by the authenticated user'
      end

      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Get project variables' do
          success Entities::Ci::Variable
          tags %w[ci_variables]
        end
        params do
          use :pagination
        end
        get ':id/variables', urgency: :low do
          variables = user_project.variables
          present paginate(variables), with: Entities::Ci::Variable
        end

        desc 'Get the details of a single variable from a project' do
          success Entities::Ci::Variable
          failure [{ code: 404, message: 'Variable Not Found' }]
          tags %w[ci_variables]
        end
        params do
          requires :key, type: String, desc: 'The key of a variable'
          optional :filter, type: Hash, desc: 'Available filters: [environment_scope]. Example: filter[environment_scope]=production' do
            optional :environment_scope, type: String, desc: 'The environment scope of a variable'
          end
        end
        get ':id/variables/:key', urgency: :low do
          variable = find_variable(user_project, params)
          not_found!('Variable') unless variable

          present variable, with: Entities::Ci::Variable
        end

        desc 'Create a new variable in a project' do
          success Entities::Ci::Variable
          failure [{ code: 400, message: '400 Bad Request' }]
          tags %w[ci_variables]
        end
        route_setting :log_safety, { safe: %w[key], unsafe: %w[value] }
        params do
          requires :key, type: String, desc: 'The key of a variable'
          requires :value, type: String, desc: 'The value of a variable'
          optional :protected, type: Boolean, desc: 'Whether the variable is protected'
          optional :masked, type: Boolean, desc: 'Whether the variable is masked'
          optional :masked_and_hidden, type: Boolean, desc: 'Whether the variable is masked and hidden'
          optional :raw, type: Boolean, desc: 'Whether the variable will be expanded'
          optional :variable_type, type: String, values: ::Ci::Variable.variable_types.keys, desc: 'The type of the variable. Default: env_var'
          optional :environment_scope, type: String, desc: 'The environment_scope of the variable'
          optional :description, type: String, desc: 'The description of the variable'
        end
        post ':id/variables' do
          variable = ::Ci::ChangeVariableService.new(
            container: user_project,
            current_user: current_user,
            params: { action: :create, variable_params: declared_params(include_missing: false) }
          ).execute

          if variable.valid?
            present variable, with: Entities::Ci::Variable
          else
            render_validation_error!(variable)
          end
        end

        desc 'Update an existing variable from a project' do
          success Entities::Ci::Variable
          failure [{ code: 404, message: 'Variable Not Found' }]
          tags %w[ci_variables]
        end
        route_setting :log_safety, { safe: %w[key], unsafe: %w[value] }
        params do
          optional :key, type: String, desc: 'The key of a variable'
          optional :value, type: String, desc: 'The value of a variable'
          optional :protected, type: Boolean, desc: 'Whether the variable is protected'
          optional :masked, type: Boolean, desc: 'Whether the variable is masked'
          optional :environment_scope, type: String, desc: 'The environment_scope of a variable'
          optional :raw, type: Boolean, desc: 'Whether the variable will be expanded'
          optional :variable_type, type: String, values: ::Ci::Variable.variable_types.keys, desc: 'The type of the variable. Default: env_var'
          optional :filter, type: Hash, desc: 'Available filters: [environment_scope]. Example: filter[environment_scope]=production' do
            optional :environment_scope, type: String, desc: 'The environment scope of a variable'
          end
          optional :description, type: String, desc: 'The description of the variable'
        end
        put ':id/variables/:key' do
          variable = find_variable(user_project, params)
          not_found!('Variable') unless variable

          variable = ::Ci::ChangeVariableService.new(
            container: user_project,
            current_user: current_user,
            params: { action: :update, variable: variable, variable_params: declared_params(include_missing: false).except(:key, :filter) }
          ).execute

          if variable.valid?
            present variable, with: Entities::Ci::Variable
          else
            render_validation_error!(variable)
          end
        end

        desc 'Delete an existing variable from a project' do
          success Entities::Ci::Variable
          failure [{ code: 404, message: 'Variable Not Found' }]
          tags %w[ci_variables]
        end
        params do
          requires :key, type: String, desc: 'The key of a variable'
          optional :filter, type: Hash, desc: 'Available filters: [environment_scope]. Example: filter[environment_scope]=production' do
            optional :environment_scope, type: String, desc: 'The environment scope of the variable'
          end
        end
        delete ':id/variables/:key' do
          variable = find_variable(user_project, params)
          not_found!('Variable') unless variable

          ::Ci::ChangeVariableService.new(
            container: user_project,
            current_user: current_user,
            params: { action: :destroy, variable: variable }
          ).execute

          no_content!
        end
      end
    end
  end
end
