# frozen_string_literal: true

module Packages
  module Conan
    class SearchService < BaseService
      WILDCARD = '*'
      MAX_WILDCARD_COUNT = 5
      MAX_SEARCH_TERM_LENGTH = 200

      ERRORS = {
        search_term_too_long: ServiceResponse.error(
          message: "Search term length must be less than #{MAX_SEARCH_TERM_LENGTH} characters.",
          reason: :invalid_parameter
        ),
        too_many_wildcards: ServiceResponse.error(
          message: "Too many wildcards in search term. Maximum is #{MAX_WILDCARD_COUNT}.",
          reason: :invalid_parameter
        )
      }.freeze

      def execute
        return ERRORS[:search_term_too_long] if search_term_too_long?
        return ERRORS[:too_many_wildcards] if too_many_wildcards?

        ServiceResponse.success(payload: { results: search_results })
      end

      private

      def search_results
        return [] if wildcard_query?

        search_packages
      end

      def query
        params[:query]
      end

      def wildcard_query?
        query == WILDCARD
      end

      def search_term_too_long?
        query.length > MAX_SEARCH_TERM_LENGTH
      end

      def too_many_wildcards?
        query.count(WILDCARD) > MAX_WILDCARD_COUNT
      end

      def search_packages
        ::Packages::Conan::PackageFinder
          .new(current_user, { query: query }, project: project)
          .execute
          .map(&:conan_recipe)
      end
    end
  end
end
