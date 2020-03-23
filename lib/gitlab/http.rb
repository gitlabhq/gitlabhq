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
      SocketError, OpenSSL::SSL::SSLError, OpenSSL::OpenSSLError,
      Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
      Net::OpenTimeout, Net::ReadTimeout, Gitlab::HTTP::BlockedUrlError,
      Gitlab::HTTP::RedirectionTooDeep
    ].freeze

    include HTTParty # rubocop:disable Gitlab/HTTParty

    connection_adapter HTTPConnectionAdapter

    def self.perform_request(http_method, path, options, &block)
      super
    rescue HTTParty::RedirectionTooDeep
      raise RedirectionTooDeep
    end

    def self.try_get(path, options = {}, &block)
      log_info = options.delete(:extra_log_info)
      self.get(path, options, &block)

    rescue *HTTP_ERRORS => e
      extra_info = log_info || {}
      extra_info = log_info.call(e, path, options) if log_info.respond_to?(:call)

      Gitlab::ErrorTracking.log_exception(e, extra_info)
      nil
    end
  end
end
