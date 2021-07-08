# frozen_string_literal: true

module BulkImports
  module Common
    module Extractors
      class RestExtractor
        def initialize(options = {})
          @query = options[:query]
        end

        def extract(context)
          client = http_client(context.configuration)
          params = query.to_h(context)
          response = client.get(params[:resource], params[:query])

          BulkImports::Pipeline::ExtractedData.new(
            data: response.parsed_response,
            page_info: page_info(response.headers)
          )
        end

        private

        attr_reader :query

        def http_client(configuration)
          @http_client ||= BulkImports::Clients::HTTP.new(
            url: configuration.url,
            token: configuration.access_token,
            per_page: 100
          )
        end

        def page_info(headers)
          next_page = headers['x-next-page']

          {
            'has_next_page' => next_page.present?,
            'next_page' => next_page
          }
        end
      end
    end
  end
end
