# frozen_string_literal: true

module BulkImports
  module Common
    module Extractors
      class GraphqlExtractor
        def initialize(query)
          @query = query[:query]
          @query_string = @query.to_s
          @variables = @query.variables
        end

        def extract(context)
          @context = context

          Enumerator.new do |yielder|
            context.entities.each do |entity|
              result = graphql_client.execute(parsed_query, query_variables(entity))

              yielder << result.original_hash.deep_dup
            end
          end
        end

        private

        def graphql_client
          @graphql_client ||= BulkImports::Clients::Graphql.new(
            url: @context.configuration.url,
            token: @context.configuration.access_token
          )
        end

        def parsed_query
          @parsed_query ||= graphql_client.parse(@query.to_s)
        end

        def query_variables(entity)
          return unless @variables

          @variables.transform_values do |entity_attribute|
            entity.public_send(entity_attribute) # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end
    end
  end
end
