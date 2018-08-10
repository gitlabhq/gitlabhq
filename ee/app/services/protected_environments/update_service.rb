# frozen_string_literal: true
module ProtectedEnvironments
  class UpdateService < BaseService
    def execute(protected_environment)
      protected_environment.update(params)
    end
  end
end
