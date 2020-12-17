# frozen_string_literal: true

module BulkImports
  module Common
    module Extractors
      class GraphqlExtractor
        def initialize(query)
          @query = query[:query]
        end

        def extract(context)
          client = graphql_client(context)

          Enumerator.new do |yielder|
            result = client.execute(
              client.parse(query.to_s),
              query.variables(context.entity)
            )

            yielder << result.original_hash.deep_dup
          end
        end

        private

        attr_reader :query

        def graphql_client(context)
          @graphql_client ||= BulkImports::Clients::Graphql.new(
            url: context.configuration.url,
            token: context.configuration.access_token
          )
        end

        def parsed_query
          @parsed_query ||= graphql_client.parse(query.to_s)
        end
      end
    end
  end
end
