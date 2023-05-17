# frozen_string_literal: true

module Packages
  module Conan
    class SearchService < BaseService
      include ActiveRecord::Sanitization::ClassMethods

      WILDCARD = '*'
      RECIPE_SEPARATOR = '@'

      def execute
        ServiceResponse.success(payload: { results: search_results })
      end

      private

      def search_results
        return [] if wildcard_query?

        return search_for_single_package(sanitized_query) if params[:query].include?(RECIPE_SEPARATOR)

        search_packages
      end

      def wildcard_query?
        params[:query] == WILDCARD
      end

      def sanitized_query
        @sanitized_query ||= sanitize_sql_like(params[:query].delete(WILDCARD))
      end

      def search_for_single_package(query)
        ::Packages::Conan::SinglePackageSearchService
          .new(query, current_user)
          .execute[:results]
      end

      def search_packages
        ::Packages::Conan::PackageFinder
          .new(current_user, { query: build_query }, project: project)
          .execute
          .map(&:conan_recipe)
      end

      def build_query
        return "#{sanitized_query}%" if params[:query].end_with?(WILDCARD)

        sanitized_query
      end
    end
  end
end
