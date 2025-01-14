# frozen_string_literal: true

module ActiveContext
  module Databases
    module Postgresql
      class QueryResult
        include ActiveContext::Databases::Concerns::QueryResult

        def initialize(pg_result)
          @pg_result = pg_result
        end

        def each
          return enum_for(:each) unless block_given?

          pg_result.each do |row|
            yield row
          end
        end

        def count
          pg_result.ntuples
        end

        def clear
          pg_result.clear if pg_result.respond_to?(:clear)
        end

        private

        attr_reader :pg_result
      end
    end
  end
end
