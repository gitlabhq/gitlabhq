# frozen_string_literal: true

module ActiveContext
  module Databases
    module Postgresql
      class QueryResult
        include ActiveContext::Databases::Concerns::QueryResult

        def each
          return enum_for(:each) unless block_given?

          result.each do |row|
            yield row
          end
        end

        def count
          result.ntuples
        end

        def clear
          result.clear if result.respond_to?(:clear)
        end
      end
    end
  end
end
