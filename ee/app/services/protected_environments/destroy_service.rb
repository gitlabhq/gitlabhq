# frozen_string_literal: true
module ProtectedEnvironments
  class DestroyService < BaseService
    def execute(protected_environment)
      protected_environment.destroy
    end
  end
end
