module API
  # Projects variables API
  class Variables < Grape::API
    before { authenticate! }
    before { authorize! :admin_build, user_project }

    resource :projects do
      desc 'Get project variables' do
        success Entities::Variable
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a project'
        optional :page, type: Integer, desc: 'The page number for pagination'
        optional :per_page, type: Integer, desc: 'The value of items per page to show'
      end
      get ':id/variables' do
        variables = user_project.variables
        present paginate(variables), with: Entities::Variable
      end

      desc 'Get specific variable of a project' do
        success Entities::Variable
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a project'
        requires :key, type: String, desc: 'The key of the variable'
      end
      get ':id/variables/:key' do
        key = params[:key]
        variable = user_project.variables.find_by(key: key.to_s)

        return not_found!('Variable') unless variable

        present variable, with: Entities::Variable
      end

      desc 'Create a new variable in project' do
        success Entities::Variable
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a project'
        requires :key, type: String, desc: 'The key of the variable'
        requires :value, type: String, desc: 'The value of the variable'
      end
      post ':id/variables' do
        required_attributes! [:key, :value]

        variable = user_project.variables.create(key: params[:key], value: params[:value])

        if variable.valid?
          present variable, with: Entities::Variable
        else
          render_validation_error!(variable)
        end
      end

      desc 'Update existing variable of a project' do
        success Entities::Variable
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a project'
        optional :key, type: String, desc: 'The key of the variable'
        optional :value, type: String, desc: 'TNew value for `value` field of the variable'
      end
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

      desc 'Delete existing variable of a project' do
        success Entities::Variable
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a project'
        requires :key, type: String, desc: 'The key of the variable'
      end
      delete ':id/variables/:key' do
        variable = user_project.variables.find_by(key: params[:key].to_s)

        return not_found!('Variable') unless variable
        variable.destroy

        present variable, with: Entities::Variable
      end
    end
  end
end
