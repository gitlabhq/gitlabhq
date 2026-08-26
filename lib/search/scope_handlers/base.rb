# frozen_string_literal: true

module Search
  module ScopeHandlers
    class Base
      DEFAULT_PAGE = 1
      DEFAULT_PER_PAGE = 20
      COUNT_LIMIT = 100
      COUNT_LIMIT_MESSAGE = "#{COUNT_LIMIT - 1}+".freeze

      attr_reader :search_results, :current_user, :query, :filters

      def self.scope_name
        raise NotImplementedError, "#{name} must implement .scope_name"
      end

      def initialize(search_results)
        @search_results = search_results
        @current_user = search_results.current_user
        @query = search_results.query
        @filters = search_results.filters
      end

      def objects(page: nil, per_page: DEFAULT_PER_PAGE, preload_method: nil)
        page = (page || DEFAULT_PAGE).to_i
        records = fetch_results(page: page, per_page: per_page, preload_method: preload_method)

        Kaminari.paginate_array(
          records.to_a,
          total_count: total_count,
          limit: per_page,
          offset: per_page * (page - 1)
        )
      end

      def count
        @count ||= [total_count, COUNT_LIMIT].min
      end

      def formatted_count
        if count >= COUNT_LIMIT
          COUNT_LIMIT_MESSAGE
        else
          count.to_s
        end
      end

      def highlight_map
        {}
      end

      def aggregations
        []
      end

      private

      def fetch_results(page:, per_page:, preload_method: nil)
        raise NotImplementedError, "#{self.class.name} must implement #fetch_results"
      end

      def total_count
        raise NotImplementedError, "#{self.class.name} must implement #total_count"
      end
    end
  end
end
