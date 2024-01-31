# frozen_string_literal: true

module Environments
  class DestroyService < BaseService
    def execute(environment)
      unless can?(current_user, :destroy_environment, environment)
        return ServiceResponse.error(
          message: 'Unauthorized to delete the environment'
        )
      end

      environment.destroy

      unless environment.destroyed?
        return ServiceResponse.error(
          message: 'Attempted to destroy the environment but failed'
        )
      end

      ServiceResponse.success
    end
  end
end
