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
      return [] if @search.blank?

      Route
        .for_routable(routables)
        .sort_by_path_length
        .fuzzy_search(@search, [:path])
        .limit(LIMIT) # rubocop: disable CodeReuse/ActiveRecord
    end

    private

    def routables
      raise NotImplementedError
    end

    class NamespacesOnly < self
      def routables
        return Namespace.all if current_user.admin?

        current_user.namespaces
      end
    end

    class ProjectsOnly < self
      def routables
        return Project.all if current_user.admin?

        current_user.projects
      end
    end
  end
end
