# frozen_string_literal: true

module FeatureFlags
  class EnableService < BaseService
    def execute
      if feature_flag_by_name
        update_feature_flag
      else
        create_feature_flag
      end
    end

    private

    def create_feature_flag
      ::FeatureFlags::CreateService
        .new(project, current_user, create_params)
        .execute
    end

    def update_feature_flag
      ::FeatureFlags::UpdateService
        .new(project, current_user, update_params)
        .execute(feature_flag_by_name)
    end

    def create_params
      if params[:environment_scope] == '*'
        params_to_create_flag_with_default_scope
      else
        params_to_create_flag_with_additional_scope
      end
    end

    def update_params
      if feature_flag_scope_by_environment_scope
        params_to_update_scope
      else
        params_to_create_scope
      end
    end

    def params_to_create_flag_with_default_scope
      {
        name: params[:name],
        scopes_attributes: [
          {
            active: true,
            environment_scope: '*',
            strategies: [params[:strategy]]
          }
        ]
      }
    end

    def params_to_create_flag_with_additional_scope
      {
        name: params[:name],
        scopes_attributes: [
          {
            active: false,
            environment_scope: '*'
          },
          {
            active: true,
            environment_scope: params[:environment_scope],
            strategies: [params[:strategy]]
          }
        ]
      }
    end

    def params_to_create_scope
      {
        scopes_attributes: [{
          active: true,
          environment_scope: params[:environment_scope],
          strategies: [params[:strategy]]
        }]
      }
    end

    def params_to_update_scope
      {
        scopes_attributes: [{
          id: feature_flag_scope_by_environment_scope.id,
          active: true,
          strategies: feature_flag_scope_by_environment_scope.strategies | [params[:strategy]]
        }]
      }
    end
  end
end
