# frozen_string_literal: true

require 'net/http'
require 'json'

module Gitlab
  module Danger
    module RequestHelper
      HTTPError = Class.new(RuntimeError)

      # @param [String] url
      def self.http_get_json(url)
        rsp = Net::HTTP.get_response(URI.parse(url))

        unless rsp.is_a?(Net::HTTPOK)
          raise HTTPError, "Failed to read #{url}: #{rsp.code} #{rsp.message}"
        end

        Gitlab::Json.parse(rsp.body)
      end
    end
  end
end
