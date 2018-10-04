module Gitlab
  module Search
    class ParsedQuery
      attr_reader :term, :filters

      def initialize(term, filters)
        @term = term
        @filters = filters
      end

      def filter_results(results)
        filters = @filters.reject { |filter| filter[:matcher].nil? }
        return unless filters

        results.select do |result|
          filters.all? do |filter|
            filter[:matcher].call(filter, result)
          end
        end
      end
    end
  end
end
