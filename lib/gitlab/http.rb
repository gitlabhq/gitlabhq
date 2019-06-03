# frozen_string_literal: true

# This class is used as a proxy for all outbounding http connection
# coming from callbacks, services and hooks. The direct use of the HTTParty
# is discouraged because it can lead to several security problems, like SSRF
# calling internal IP or services.
module Gitlab
  class HTTP
    BlockedUrlError = Class.new(StandardError)
    RedirectionTooDeep = Class.new(StandardError)

    HTTP_ERRORS = [
      SocketError, OpenSSL::SSL::SSLError, Errno::ECONNRESET,
      Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Net::OpenTimeout,
      Net::ReadTimeout, Gitlab::HTTP::BlockedUrlError,
      Gitlab::HTTP::RedirectionTooDeep
    ].freeze

    include HTTParty # rubocop:disable Gitlab/HTTParty

    connection_adapter HTTPConnectionAdapter

    def self.perform_request(http_method, path, options, &block)
      super
    rescue HTTParty::RedirectionTooDeep
      raise RedirectionTooDeep
    end
  end
end
