# frozen_string_literal: true

module BulkImports
  module Groups
    module Extractors
      class SubgroupsExtractor
        def extract(context)
          encoded_parent_path = ERB::Util.url_encode(context.entity.source_full_path)

          response = http_client(context.configuration)
            .each_page(:get, "groups/#{encoded_parent_path}/subgroups")
            .flat_map(&:itself)

          BulkImports::Pipeline::ExtractedData.new(data: response)
        end

        private

        def http_client(configuration)
          @http_client ||= BulkImports::Clients::HTTP.new(
            url: configuration.url,
            token: configuration.access_token,
            per_page: 100
          )
        end
      end
    end
  end
end
