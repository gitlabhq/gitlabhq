# frozen_string_literal: true

require 'net/http'

module Gitlab
  module HTTP_V2
    BlockedUrlError = Class.new(StandardError)
    RedirectionTooDeep = Class.new(StandardError)
    ReadTotalTimeout = Class.new(Net::ReadTimeout)
    HeaderReadTimeout = Class.new(Net::ReadTimeout)
    SilentModeBlockedError = Class.new(StandardError)

    HTTP_TIMEOUT_ERRORS = [
      Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, Gitlab::HTTP_V2::ReadTotalTimeout
    ].freeze

    HTTP_ERRORS = HTTP_TIMEOUT_ERRORS + [
      EOFError, SocketError, OpenSSL::SSL::SSLError, OpenSSL::OpenSSLError,
      Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH,
      Gitlab::HTTP_V2::BlockedUrlError, Gitlab::HTTP_V2::RedirectionTooDeep,
      Net::HTTPBadResponse
    ].freeze
  end
end
