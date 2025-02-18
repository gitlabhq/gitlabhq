# frozen_string_literal: true

module API
  class GroupVariables < ::API::Base
    include PaginationParams

    before { authenticate! }
    before { authorize! :admin_cicd_variables, user_group }
    feature_category :ci_variables

    helpers ::API::Helpers::VariablesHelpers

    params do
      requires :id, type: String, desc: 'The ID of a group or URL-encoded path of the group owned by the authenticated
      user'
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of group-level variables' do
        success Entities::Ci::Variable
        tags %w[ci_variables]
      end
      params do
        use :pagination
      end
      get ':id/variables', urgency: :low do
        variables = user_group.variables
        present paginate(variables), with: Entities::Ci::Variable
      end

      desc 'Get the details of a group’s specific variable' do
        success Entities::Ci::Variable
        failure [{ code: 404, message: 'Group Variable Not Found' }]
        tags %w[ci_variables]
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
        failure [{ code: 400, message: '400 Bad Request' }]
        tags %w[ci_variables]
      end
      route_setting :log_safety, { safe: %w[key], unsafe: %w[value] }
      params do
        requires :key, type: String, desc: 'The ID of a group or URL-encoded path of the group owned by the
        authenticated user'
        requires :value, type: String, desc: 'The value of a variable'
        optional :protected, type: String, desc: 'Whether the variable is protected'
        optional :masked_and_hidden, type: String, desc: 'Whether the variable is masked and hidden'
        optional :masked, type: String, desc: 'Whether the variable is masked'
        optional :raw, type: String, desc: 'Whether the variable will be expanded'
        optional :variable_type, type: String, values: ::Ci::GroupVariable.variable_types.keys, desc: 'The type of the variable. Default: env_var'
        optional :environment_scope, type: String, desc: 'The environment scope of a variable'
        optional :description, type: String, desc: 'The description of the variable'

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
        failure [{ code: 400, message: '400 Bad Request' }, { code: 404, message: 'Group Variable Not Found' }]
        tags %w[ci_variables]
      end
      route_setting :log_safety, { safe: %w[key], unsafe: %w[value] }
      params do
        optional :key, type: String, desc: 'The key of a variable'
        optional :value, type: String, desc: 'The value of a variable'
        optional :protected, type: String, desc: 'Whether the variable is protected'
        optional :masked, type: String, desc: 'Whether the variable is masked'
        optional :raw, type: String, desc: 'Whether the variable will be expanded'
        optional :variable_type, type: String, values: ::Ci::GroupVariable.variable_types.keys, desc: 'The type of the variable. Default: env_var'
        optional :environment_scope, type: String, desc: 'The environment scope of a variable'
        optional :description, type: String, desc: 'The description of the variable'

        use :optional_group_variable_params_ee
      end
      put ':id/variables/:key' do
        filtered_params = filter_variable_parameters(
          user_group,
          declared_params(include_missing: false)
        )

        # If the 'filter' parameter is provided, the user is updating a scoped variable
        # and we need to use `find_variable` to make sure we update the correct one.
        # However, this would result in an error response in case the user attempts to
        # update a scoped variable without providing a filter. This error response is
        # technically correct, because updating a scoped variable without specifying
        # the targeted scope causes non-deterministic behavior. But this endpoint was
        # originally introduced without the ability to specify a filter, and returning
        # an error in these cases now would be considered a breaking change.
        # Thus we only use the new/correct code if the user provided a filter.
        # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136475
        if params.key?('filter')
          variable = find_variable(user_group, params)

          variable = ::Ci::ChangeVariableService.new(
            container: user_group,
            current_user: current_user,
            params: { action: :update, variable: variable, variable_params: filtered_params }
          ).execute
        else
          variable = ::Ci::ChangeVariableService.new(
            container: user_group,
            current_user: current_user,
            params: { action: :update, variable_params: filtered_params }
          ).execute
        end

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
        failure [{ code: 404, message: 'Group Variable Not Found' }]
        tags %w[ci_variables]
      end
      params do
        requires :key, type: String, desc: 'The key of a variable'
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
