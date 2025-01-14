# frozen_string_literal: true

# Takes in an incoming request and extracts contextual information such as location.
#
# Information about country and city of the request is taken from its headers set by Cloudflare WAF.
# See: https://developers.cloudflare.com/rules/transform/managed-transforms/reference/#add-visitor-location-headers
#
module Gitlab
  module Auth
    class VisitorLocation
      attr_reader :request

      HEADERS = {
        country: 'Cf-Ipcountry',
        city: 'Cf-Ipcity'
      }.freeze

      # @param [ActionDispatch::Request] request
      def initialize(request)
        @request = request
      end

      def country
        code = request.headers[HEADERS[:country]] # 2-letter country code, e.g. "JP" for Japan
        # If country name is not known for local language, default to English. Or just display country code
        I18nData.countries(I18n.locale)[code] || code
      rescue I18nData::NoTranslationAvailable
        I18nData.countries[code] || code
      end

      def city
        request.headers[HEADERS[:city]]
      end
    end
  end
end
