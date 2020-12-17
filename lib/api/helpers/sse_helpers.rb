# frozen_string_literal: true

module API
  module Helpers
    module SSEHelpers
      def request_from_sse?(project)
        return false if request.referer.blank?

        uri = URI.parse(request.referer)
        uri.path.starts_with?(::Gitlab::Routing.url_helpers.project_root_sse_path(project))
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
