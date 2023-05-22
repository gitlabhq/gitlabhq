# frozen_string_literal: true

module Environments
  class CreateService < BaseService
    def execute
      unless can?(current_user, :create_environment, project)
        return ServiceResponse.error(
          message: _('Unauthorized to create an environment'),
          payload: { environment: nil }
        )
      end

      environment = project.environments.create(**params)

      if environment.persisted?
        ServiceResponse.success(payload: { environment: environment })
      else
        ServiceResponse.error(
          message: environment.errors.full_messages,
          payload: { environment: nil }
        )
      end
    end
  end
end
