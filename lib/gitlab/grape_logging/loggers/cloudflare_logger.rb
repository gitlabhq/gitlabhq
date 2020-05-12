# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Loggers
      class CloudflareLogger < ::GrapeLogging::Loggers::Base
        include ::Gitlab::Logging::CloudflareHelper

        def parameters(request, _response)
          data = {}
          store_cloudflare_headers!(data, request)

          data
        end
      end
    end
  end
end
