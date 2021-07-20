# frozen_string_literal: true

module Packages
  module Conan
    class SearchService < BaseService
      include ActiveRecord::Sanitization::ClassMethods

      WILDCARD = '*'
      RECIPE_SEPARATOR = '@'

      def initialize(user, params)
        super(nil, user, params)
      end

      def execute
        ServiceResponse.success(payload: { results: search_results })
      end

      private

      def search_results
        return [] if wildcard_query?

        return search_for_single_package(sanitized_query) if params[:query].include?(RECIPE_SEPARATOR)

        search_packages(build_query)
      end

      def wildcard_query?
        params[:query] == WILDCARD
      end

      def build_query
        return "#{sanitized_query}%" if params[:query].end_with?(WILDCARD)

        sanitized_query
      end

      def search_packages(query)
        ::Packages::Conan::PackageFinder.new(current_user, query: query).execute.map(&:conan_recipe)
      end

      def search_for_single_package(query)
        name, version, username, _ = query.split(%r{[@/]})
        full_path = Packages::Conan::Metadatum.full_path_from(package_username: username)
        project = Project.find_by_full_path(full_path)
        return unless Ability.allowed?(current_user, :read_package, project)

        result = project.packages.with_name(name).with_version(version).order_created.last
        [result&.conan_recipe].compact
      end

      def sanitized_query
        @sanitized_query ||= sanitize_sql_like(params[:query].delete(WILDCARD))
      end
    end
  end
end
