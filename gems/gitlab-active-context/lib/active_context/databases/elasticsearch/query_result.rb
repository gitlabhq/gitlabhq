# frozen_string_literal: true

module ActiveContext
  module Databases
    module Elasticsearch
      class QueryResult
        include ActiveContext::Databases::Concerns::QueryResult

        def each
          return enum_for(:each) unless block_given?

          result['hits']['hits'].each do |hit|
            yield hit['_source']
          end
        end
      end
    end
  end
end
