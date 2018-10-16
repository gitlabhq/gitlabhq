# frozen_string_literal: true

module QA
  module Runtime
    module Fixtures
      def fetch_template_from_api(api_path, key)
        request = Runtime::API::Request.new(api_client, "/templates/#{api_path}/#{key}")
        get request.url
        json_body[:content]
      end

      private

      def api_client
        @api_client ||= Runtime::API::Client.new(:gitlab)
      end
    end
  end
end
