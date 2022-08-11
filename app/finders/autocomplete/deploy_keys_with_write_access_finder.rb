# frozen_string_literal: true

module Autocomplete
  # Finder for retrieving deploy keys to use for autocomplete data sources.
  class DeployKeysWithWriteAccessFinder
    attr_reader :current_user, :project

    def initialize(current_user, project)
      @current_user = current_user
      @project = project
    end

    def execute
      return DeployKey.none if project.nil?

      raise Gitlab::Access::AccessDeniedError unless current_user.can?(:admin_project, project)

      project.deploy_keys.merge(DeployKeysProject.with_write_access)
    end
  end
end
