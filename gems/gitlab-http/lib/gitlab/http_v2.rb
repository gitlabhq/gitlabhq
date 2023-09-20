# frozen_string_literal: true

require_relative "http_v2/configuration"
require_relative "http_v2/patches"
require_relative "http_v2/client"

module Gitlab
  module HTTP_V2
    SUPPORTED_HTTP_METHODS = [:get, :try_get, :post, :patch, :put, :delete, :head, :options].freeze

    class << self
      delegate(*SUPPORTED_HTTP_METHODS, to: ::Gitlab::HTTP_V2::Client)

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end
    end
  end
end
