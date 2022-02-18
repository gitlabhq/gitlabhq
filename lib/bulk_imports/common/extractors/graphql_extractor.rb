# frozen_string_literal: true

module BulkImports
  module Common
    module Extractors
      class GraphqlExtractor
        def initialize(options = {})
          @query_klass = options[:query]
        end

        def extract(context)
          client = graphql_client(context)
          query = query_klass.new(context: context)

          response = client.execute(
            client.parse(query.to_s),
            query.variables
          ).original_hash.deep_dup

          BulkImports::Pipeline::ExtractedData.new(
            data: response.dig(*query.data_path),
            page_info: response.dig(*query.page_info_path)
          )
        end

        private

        attr_reader :query_klass

        def graphql_client(context)
          @graphql_client ||= BulkImports::Clients::Graphql.new(
            url: context.configuration.url,
            token: context.configuration.access_token
          )
        end
      end
    end
  end
end
