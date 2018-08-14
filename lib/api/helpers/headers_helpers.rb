module API
  module Helpers
    module HeadersHelpers
      def set_http_headers(header_data)
        header_data.each do |key, value|
          if value.is_a?(Enumerable)
            raise ArgumentError.new("Header value should be a string")
          end

          header "X-Gitlab-#{key.to_s.split('_').collect(&:capitalize).join('-')}", value.to_s
        end
      end
    end
  end
end
