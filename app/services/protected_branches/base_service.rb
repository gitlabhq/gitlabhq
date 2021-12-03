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

    def filtered_params
      return unless params

      params[:name] = sanitize_branch_name(params[:name]) if params[:name].present?
      params
    end

    private

    def sanitize_branch_name(name)
      name = CGI.unescapeHTML(name)
      name = Sanitize.fragment(name)

      # Sanitize.fragment escapes HTML chars, so unescape again to allow names
      # like `feature->master`
      CGI.unescapeHTML(name)
    end
  end
end
