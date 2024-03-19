# frozen_string_literal: true

module Autocomplete
  # Finder for retrieving deploy keys to use for autocomplete data sources.
  class DeployKeysWithWriteAccessFinder
    attr_reader :current_user, :project

    def initialize(current_user, project)
      @current_user = current_user
      @project = project
    end

    def execute(title_search_term: nil)
      return DeployKey.none if project.nil?

      raise Gitlab::Access::AccessDeniedError unless current_user.can?(:admin_project, project)

      relation = DeployKey.with_write_access.in_projects(project)
      relation = relation.fuzzy_search(title_search_term, [:title]) if title_search_term.present?
      relation
    end
  end
end
