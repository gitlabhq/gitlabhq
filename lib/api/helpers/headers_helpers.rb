# frozen_string_literal: true

module API
  module Helpers
    module HeadersHelpers
      include Gitlab::NoCacheHeaders

      def set_http_headers(header_data)
        header_data.each do |key, value|
          if value.is_a?(Enumerable)
            raise ArgumentError.new("Header value should be a string")
          end

          header "X-Gitlab-#{key.to_s.split('_').collect(&:capitalize).join('-')}", value.to_s
        end
      end

      def no_cache_headers
        DEFAULT_GITLAB_NO_CACHE_HEADERS.each do |k, v|
          header k, v
        end
      end
    end
  end
end
