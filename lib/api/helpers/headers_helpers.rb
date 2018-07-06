module API
  module Helpers
    module HeadersHelpers
      def set_http_headers(header_data)
        header_data.each do |key, value|
          header "X-Gitlab-#{key.to_s.split('_').collect(&:capitalize).join('-')}", value
        end
      end
    end
  end
end
