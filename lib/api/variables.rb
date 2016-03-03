module API
  # Projects variables API
  class Variables < Grape::API
    before { authenticate! }
    before { authorize! :admin_build, user_project }

    resource :projects do
      # Get project variables
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   page (optional) - The page number for pagination
      #   per_page (optional) - The value of items per page to show
      # Example Request:
      #   GET /projects/:id/variables
      get ':id/variables' do
        variables = user_project.variables
        present paginate(variables), with: Entities::Variable
      end

      # Get specific variable of a project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   key (required) - The `key` of variable
      # Example Request:
      #   GET /projects/:id/variables/:key
      get ':id/variables/:key' do
        key = params[:key]
        variable = user_project.variables.find_by(key: key.to_s)

        return not_found!('Variable') unless variable

        present variable, with: Entities::Variable
      end

      # Create a new variable in project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   key (required) - The key of variable
      #   value (required) - The value of variable
      # Example Request:
      #   POST /projects/:id/variables
      post ':id/variables' do
        required_attributes! [:key, :value]

        variable = user_project.variables.create(key: params[:key], value: params[:value])

        if variable.valid?
          present variable, with: Entities::Variable
        else
          render_validation_error!(variable)
        end
      end

      # Update existing variable of a project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   key (optional) - The `key` of variable
      #   value (optional) - New value for `value` field of variable
      # Example Request:
      #   PUT /projects/:id/variables/:key
      put ':id/variables/:key' do
        variable = user_project.variables.find_by(key: params[:key].to_s)

        return not_found!('Variable') unless variable

        attrs = attributes_for_keys [:value]
        if variable.update(attrs)
          present variable, with: Entities::Variable
        else
          render_validation_error!(variable)
        end
      end

      # Delete existing variable of a project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   key (required) - The ID of a variable
      # Example Request:
      #   DELETE /projects/:id/variables/:key
      delete ':id/variables/:key' do
        variable = user_project.variables.find_by(key: params[:key].to_s)

        return not_found!('Variable') unless variable
        variable.destroy

        present variable, with: Entities::Variable
      end
    end
  end
end
