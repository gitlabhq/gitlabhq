module API
  class Variables < Grape::API
    include PaginationParams

    before { authenticate! }
    before { authorize! :admin_build, user_project }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS  do
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
      get ':id/variables/:key' do
        key = params[:key]
        variable = user_project.variables.find_by(key: key)

        return not_found!('Variable') unless variable

        present variable, with: Entities::Variable
      end

      desc 'Create a new variable in a project' do
        success Entities::Variable
      end
      params do
        requires :key, type: String, desc: 'The key of the variable'
        requires :value, type: String, desc: 'The value of the variable'
        optional :protected, type: String, desc: 'Whether the variable is protected'
      end
      post ':id/variables' do
        variable_params = declared_params(include_missing: false)

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
        optional :protected, type: String, desc: 'Whether the variable is protected'
      end
      put ':id/variables/:key' do
        variable = user_project.variables.find_by(key: params[:key])

        return not_found!('Variable') unless variable

        variable_params = declared_params(include_missing: false).except(:key)

        if variable.update(variable_params)
          present variable, with: Entities::Variable
        else
          render_validation_error!(variable)
        end
      end

      desc 'Delete an existing variable from a project' do
        success Entities::Variable
      end
      params do
        requires :key, type: String, desc: 'The key of the variable'
      end
      delete ':id/variables/:key' do
        variable = user_project.variables.find_by(key: params[:key])
        not_found!('Variable') unless variable

        # Variables don't have any timestamp. Therfore, destroy unconditionally.
        status 204
        variable.destroy
      end
    end
  end
end
