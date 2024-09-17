# frozen_string_literal: true

module Gitlab
  module Logging
    module CloudflareHelper
      CLOUDFLARE_CUSTOM_HEADERS = { 'Cf-Ray' => :cf_ray, 'Cf-Request-Id' => :cf_request_id,
                                    'Cf-IPCountry' => :cf_ipcountry, 'Cf-Worker' => :cf_worker }.freeze

      def store_cloudflare_headers!(payload, request)
        CLOUDFLARE_CUSTOM_HEADERS.each do |header, value|
          payload[value] = request.headers[header] if valid_cloudflare_header?(request.headers[header])
        end
      end

      def valid_cloudflare_header?(value)
        return false unless value.present?
        return false if value.length > 64
        return false if value.index(/[^[.A-Za-z0-9-]]/)

        true
      end
    end
  end
end
