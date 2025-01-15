# frozen_string_literal: true

module ActiveContext
  module Databases
    module Opensearch
      class QueryResult
        include ActiveContext::Databases::Concerns::QueryResult

        def initialize(result)
          @result = result
        end

        def count
          result['hits']['total']['value']
        end

        def each
          return enum_for(:each) unless block_given?

          result['hits']['hits'].each do |hit|
            yield hit['_source']
          end
        end

        private

        attr_reader :result
      end
    end
  end
end
