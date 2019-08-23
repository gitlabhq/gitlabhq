# frozen_string_literal: true

module QA
  module Runtime
    module Fixtures
      include Support::Api

      TemplateNotFoundError = Class.new(RuntimeError)

      def fetch_template_from_api(api_path, key)
        request = Runtime::API::Request.new(api_client, "/templates/#{api_path}/#{key}")
        response = get(request.url)

        unless response.code == HTTP_STATUS_OK
          raise TemplateNotFoundError, "Template at #{request.mask_url} could not be found (#{response.code}): `#{response}`."
        end

        parse_body(response)[:content]
      end

      private

      def api_client
        @api_client ||= Runtime::API::Client.new(:gitlab)
      end
    end
  end
end
