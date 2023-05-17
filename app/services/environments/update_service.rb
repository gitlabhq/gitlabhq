# frozen_string_literal: true

module Environments
  class UpdateService < BaseService
    def execute(environment)
      unless can?(current_user, :update_environment, environment)
        return ServiceResponse.error(
          message: _('Unauthorized to update the environment'),
          payload: { environment: environment }
        )
      end

      if environment.update(**params)
        ServiceResponse.success(payload: { environment: environment })
      else
        ServiceResponse.error(
          message: environment.errors.full_messages,
          payload: { environment: environment }
        )
      end
    end
  end
end
