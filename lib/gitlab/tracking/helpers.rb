# frozen_string_literal: true

module Gitlab
  module Tracking
    module Helpers
      def dnt_enabled?
        Gitlab::Utils.to_boolean(request.headers['DNT'])
      end

      def trackable_html_request?
        request.format.html? && !dnt_enabled?
      end
    end
  end
end
