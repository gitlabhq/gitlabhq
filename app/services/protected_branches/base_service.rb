# frozen_string_literal: true

module ProtectedBranches
  class BaseService < ::BaseService
    include ProtectedRefNameSanitizer

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

    private

    def filtered_params
      return unless params

      params[:name] = sanitize_name(params[:name]) if params[:name].present?
      params
    end
  end
end
