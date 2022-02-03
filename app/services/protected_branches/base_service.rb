# frozen_string_literal: true

module ProtectedBranches
  class BaseService < ::BaseService
    # current_user - The user that performs the action
    # params - A hash of parameters
    def initialize(project, current_user = nil, params = {})
      @project = project
      @current_user = current_user
      @params = params
    end

    def after_execute(*)
      # overridden in EE::ProtectedBranches module
    end
  end
end
