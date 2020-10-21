# frozen_string_literal: true

module FeatureFlags
  class DisableService < BaseService
    def execute
      return error('Feature Flag not found', 404) unless feature_flag_by_name
      return error('Feature Flag Scope not found', 404) unless feature_flag_scope_by_environment_scope
      return error('Strategy not found', 404) unless strategy_exist_in_persisted_data?

      ::FeatureFlags::UpdateService
        .new(project, current_user, update_params)
        .execute(feature_flag_by_name)
    end

    private

    def update_params
      if remaining_strategies.empty?
        params_to_destroy_scope
      else
        params_to_update_scope
      end
    end

    def remaining_strategies
      strong_memoize(:remaining_strategies) do
        feature_flag_scope_by_environment_scope.strategies.reject do |strategy|
          strategy['name'] == params[:strategy]['name'] &&
            strategy['parameters'] == params[:strategy]['parameters']
        end
      end
    end

    def strategy_exist_in_persisted_data?
      feature_flag_scope_by_environment_scope.strategies != remaining_strategies
    end

    def params_to_destroy_scope
      { scopes_attributes: [{ id: feature_flag_scope_by_environment_scope.id, _destroy: true }] }
    end

    def params_to_update_scope
      { scopes_attributes: [{ id: feature_flag_scope_by_environment_scope.id, strategies: remaining_strategies }] }
    end
  end
end
