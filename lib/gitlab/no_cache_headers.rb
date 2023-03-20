# frozen_string_literal: true

module Gitlab
  module NoCacheHeaders
    DEFAULT_GITLAB_NO_CACHE_HEADERS = {
      'Cache-Control' => "#{ActionDispatch::Http::Cache::Response::DEFAULT_CACHE_CONTROL}, no-store, no-cache",
      'Expires' => 'Fri, 01 Jan 1990 00:00:00 GMT'
    }.freeze

    def no_cache_headers
      raise "#no_cache_headers is not implemented for this object"
    end
  end
end
