# frozen_string_literal: true

module Autocomplete
  # Finder that returns a list of routes that match on the `path` attribute.
  class RoutesFinder
    attr_reader :current_user, :search

    LIMIT = 20

    def initialize(current_user, params = {})
      @current_user = current_user
      @search = params[:search]
    end

    def execute
      return Route.none if @search.blank?

      Route
        .for_routable(routables)
        .sort_by_path_length
        .fuzzy_search(@search, [:path])
        .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/421843')
        .limit(LIMIT)
    end

    private

    def routables
      raise NotImplementedError
    end

    class NamespacesOnly < self
      def routables
        if current_user.can_admin_all_resources?
          Namespace.without_project_namespaces
        else
          current_user.namespaces
        end.allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/420046")
      end
    end

    class ProjectsOnly < self
      def routables
        return Project.all if current_user.can_admin_all_resources?

        current_user.projects
      end
    end
  end
end
