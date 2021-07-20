# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class ScannedResource
          include Gitlab::Utils::StrongMemoize

          attr_reader :request_method
          attr_reader :request_uri

          delegate :scheme, :host, :port, :path, :query, to: :request_uri, prefix: :url

          def initialize(uri, request_method)
            raise ArgumentError unless uri.is_a?(URI)

            @request_method = request_method
            @request_uri = uri
          end
        end
      end
    end
  end
end
