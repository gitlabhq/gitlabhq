# frozen_string_literal: true

module API
  module Ci
    class Variables < ::API::Base
      include PaginationParams

      before { authenticate! }
      before { authorize! :admin_build, user_project }

      feature_category :pipeline_authoring

      helpers ::API::Helpers::VariablesHelpers

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end

      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Get project variables' do
          success Entities::Ci::Variable
        end
        params do
          use :pagination
        end
        get ':id/variables' do
          variables = user_project.variables
          present paginate(variables), with: Entities::Ci::Variable
        end

        desc 'Get a specific variable from a project' do
          success Entities::Ci::Variable
        end
        params do
          requires :key, type: String, desc: 'The key of the variable'
        end
        # rubocop: disable CodeReuse/ActiveRecord
        get ':id/variables/:key' do
          variable = find_variable(user_project, params)
          not_found!('Variable') unless variable

          present variable, with: Entities::Ci::Variable
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Create a new variable in a project' do
          success Entities::Ci::Variable
        end
        params do
          requires :key, type: String, desc: 'The key of the variable'
          requires :value, type: String, desc: 'The value of the variable'
          optional :protected, type: Boolean, desc: 'Whether the variable is protected'
          optional :masked, type: Boolean, desc: 'Whether the variable is masked'
          optional :variable_type, type: String, values: ::Ci::Variable.variable_types.keys, desc: 'The type of variable, must be one of env_var or file. Defaults to env_var'
          optional :environment_scope, type: String, desc: 'The environment_scope of the variable'
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
        end
        params do
          optional :key, type: String, desc: 'The key of the variable'
          optional :value, type: String, desc: 'The value of the variable'
          optional :protected, type: Boolean, desc: 'Whether the variable is protected'
          optional :masked, type: Boolean, desc: 'Whether the variable is masked'
          optional :variable_type, type: String, values: ::Ci::Variable.variable_types.keys, desc: 'The type of variable, must be one of env_var or file'
          optional :environment_scope, type: String, desc: 'The environment_scope of the variable'
          optional :filter, type: Hash, desc: 'Available filters: [environment_scope]. Example: filter[environment_scope]=production'
        end
        # rubocop: disable CodeReuse/ActiveRecord
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
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Delete an existing variable from a project' do
          success Entities::Ci::Variable
        end
        params do
          requires :key, type: String, desc: 'The key of the variable'
          optional :filter, type: Hash, desc: 'Available filters: [environment_scope]. Example: filter[environment_scope]=production'
        end
        # rubocop: disable CodeReuse/ActiveRecord
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
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
