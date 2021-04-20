# frozen_string_literal: true

module API
  class GroupVariables < ::API::Base
    include PaginationParams

    before { authenticate! }
    before { authorize! :admin_group, user_group }
    feature_category :continuous_integration

    helpers Helpers::VariablesHelpers

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get group-level variables' do
        success Entities::Ci::Variable
      end
      params do
        use :pagination
      end
      get ':id/variables' do
        variables = user_group.variables
        present paginate(variables), with: Entities::Ci::Variable
      end

      desc 'Get a specific variable from a group' do
        success Entities::Ci::Variable
      end
      params do
        requires :key, type: String, desc: 'The key of the variable'
      end
      get ':id/variables/:key' do
        variable = find_variable(user_group, params)

        break not_found!('GroupVariable') unless variable

        present variable, with: Entities::Ci::Variable
      end

      desc 'Create a new variable in a group' do
        success Entities::Ci::Variable
      end
      params do
        requires :key, type: String, desc: 'The key of the variable'
        requires :value, type: String, desc: 'The value of the variable'
        optional :protected, type: String, desc: 'Whether the variable is protected'
        optional :masked, type: String, desc: 'Whether the variable is masked'
        optional :variable_type, type: String, values: ::Ci::GroupVariable.variable_types.keys, desc: 'The type of variable, must be one of env_var or file. Defaults to env_var'

        use :optional_group_variable_params_ee
      end
      post ':id/variables' do
        filtered_params = filter_variable_parameters(
          user_group,
          declared_params(include_missing: false)
        )

        variable = ::Ci::ChangeVariableService.new(
          container: user_group,
          current_user: current_user,
          params: { action: :create, variable_params: filtered_params }
        ).execute

        if variable.valid?
          present variable, with: Entities::Ci::Variable
        else
          render_validation_error!(variable)
        end
      end

      desc 'Update an existing variable from a group' do
        success Entities::Ci::Variable
      end
      params do
        optional :key, type: String, desc: 'The key of the variable'
        optional :value, type: String, desc: 'The value of the variable'
        optional :protected, type: String, desc: 'Whether the variable is protected'
        optional :masked, type: String, desc: 'Whether the variable is masked'
        optional :variable_type, type: String, values: ::Ci::GroupVariable.variable_types.keys, desc: 'The type of variable, must be one of env_var or file'

        use :optional_group_variable_params_ee
      end
      put ':id/variables/:key' do
        filtered_params = filter_variable_parameters(
          user_group,
          declared_params(include_missing: false)
        )

        variable = ::Ci::ChangeVariableService.new(
          container: user_group,
          current_user: current_user,
          params: { action: :update, variable_params: filtered_params }
        ).execute

        if variable.valid?
          present variable, with: Entities::Ci::Variable
        else
          render_validation_error!(variable)
        end
      rescue ::ActiveRecord::RecordNotFound
        not_found!('GroupVariable')
      end

      desc 'Delete an existing variable from a group' do
        success Entities::Ci::Variable
      end
      params do
        requires :key, type: String, desc: 'The key of the variable'
      end
      delete ':id/variables/:key' do
        variable = find_variable(user_group, params)
        break not_found!('GroupVariable') unless variable

        destroy_conditionally!(variable) do |target_variable|
          ::Ci::ChangeVariableService.new(
            container: user_group,
            current_user: current_user,
            params: { action: :destroy, variable: variable }
          ).execute
        end
      end
    end
  end
end
