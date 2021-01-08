# frozen_string_literal: true

module Gitlab
  module Faraday
    ::Faraday::Request.register_middleware(gitlab_error_callback: -> { ::Gitlab::Faraday::ErrorCallback })
  end
end
