# frozen_string_literal: true

module API
  class Variables < Grape::API
    include PaginationParams

    before { authenticate! }
    before { authorize! :admin_build, user_project }

    helpers do
      def filter_variable_parameters(params)
        # This method exists so that EE can more easily filter out certain
        # parameters, without having to modify the source code directly.
        params
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get project variables' do
        success Entities::Variable
      end
      params do
        use :pagination
      end
      get ':id/variables' do
        variables = user_project.variables
        present paginate(variables), with: Entities::Variable
      end

      desc 'Get a specific variable from a project' do
        success Entities::Variable
      end
      params do
        requires :key, type: String, desc: 'The key of the variable'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/variables/:key' do
        key = params[:key]
        variable = user_project.variables.find_by(key: key)

        break not_found!('Variable') unless variable

        present variable, with: Entities::Variable
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Create a new variable in a project' do
        success Entities::Variable
      end
      params do
        requires :key, type: String, desc: 'The key of the variable'
        requires :value, type: String, desc: 'The value of the variable'
        optional :protected, type: Boolean, desc: 'Whether the variable is protected'
        optional :masked, type: Boolean, desc: 'Whether the variable is masked'
        optional :variable_type, type: String, values: Ci::Variable.variable_types.keys, desc: 'The type of variable, must be one of env_var or file. Defaults to env_var'
        optional :environment_scope, type: String, desc: 'The environment_scope of the variable'
      end
      post ':id/variables' do
        variable_params = declared_params(include_missing: false)
        variable_params = filter_variable_parameters(variable_params)

        variable = user_project.variables.create(variable_params)

        if variable.valid?
          present variable, with: Entities::Variable
        else
          render_validation_error!(variable)
        end
      end

      desc 'Update an existing variable from a project' do
        success Entities::Variable
      end
      params do
        optional :key, type: String, desc: 'The key of the variable'
        optional :value, type: String, desc: 'The value of the variable'
        optional :protected, type: Boolean, desc: 'Whether the variable is protected'
        optional :masked, type: Boolean, desc: 'Whether the variable is masked'
        optional :variable_type, type: String, values: Ci::Variable.variable_types.keys, desc: 'The type of variable, must be one of env_var or file'
        optional :environment_scope, type: String, desc: 'The environment_scope of the variable'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      put ':id/variables/:key' do
        variable = user_project.variables.find_by(key: params[:key])

        break not_found!('Variable') unless variable

        variable_params = declared_params(include_missing: false).except(:key)
        variable_params = filter_variable_parameters(variable_params)

        if variable.update(variable_params)
          present variable, with: Entities::Variable
        else
          render_validation_error!(variable)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Delete an existing variable from a project' do
        success Entities::Variable
      end
      params do
        requires :key, type: String, desc: 'The key of the variable'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ':id/variables/:key' do
        variable = user_project.variables.find_by(key: params[:key])
        not_found!('Variable') unless variable

        # Variables don't have any timestamp. Therfore, destroy unconditionally.
        status 204
        variable.destroy
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
