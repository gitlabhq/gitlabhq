# frozen_string_literal: true

# This class is used as a proxy for all outbounding http connection
# coming from callbacks, services and hooks. The direct use of the HTTParty
# is discouraged because it can lead to several security problems, like SSRF
# calling internal IP or services.
module Gitlab
  class HTTP
    BlockedUrlError = Class.new(StandardError)
    RedirectionTooDeep = Class.new(StandardError)
    ReadTotalTimeout = Class.new(Net::ReadTimeout)

    HTTP_TIMEOUT_ERRORS = [
      Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, Gitlab::HTTP::ReadTotalTimeout
    ].freeze
    HTTP_ERRORS = HTTP_TIMEOUT_ERRORS + [
      SocketError, OpenSSL::SSL::SSLError, OpenSSL::OpenSSLError,
      Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
      Gitlab::HTTP::BlockedUrlError, Gitlab::HTTP::RedirectionTooDeep
    ].freeze

    DEFAULT_TIMEOUT_OPTIONS = {
      open_timeout: 10,
      read_timeout: 20,
      write_timeout: 30
    }.freeze
    DEFAULT_READ_TOTAL_TIMEOUT = 20.seconds

    include HTTParty # rubocop:disable Gitlab/HTTParty

    class << self
      alias_method :httparty_perform_request, :perform_request
    end

    connection_adapter HTTPConnectionAdapter

    def self.perform_request(http_method, path, options, &block)
      log_info = options.delete(:extra_log_info)
      options_with_timeouts =
        if !options.has_key?(:timeout)
          options.with_defaults(DEFAULT_TIMEOUT_OPTIONS)
        else
          options
        end

      unless options.has_key?(:use_read_total_timeout)
        return httparty_perform_request(http_method, path, options_with_timeouts, &block)
      end

      start_time = Gitlab::Metrics::System.monotonic_time
      read_total_timeout = options.fetch(:timeout, DEFAULT_READ_TOTAL_TIMEOUT)

      httparty_perform_request(http_method, path, options_with_timeouts) do |fragment|
        elapsed = Gitlab::Metrics::System.monotonic_time - start_time
        raise ReadTotalTimeout, "Request timed out after #{elapsed} seconds" if elapsed > read_total_timeout

        block.call fragment if block
      end
    rescue HTTParty::RedirectionTooDeep
      raise RedirectionTooDeep
    rescue *HTTP_ERRORS => e
      extra_info = log_info || {}
      extra_info = log_info.call(e, path, options) if log_info.respond_to?(:call)
      Gitlab::ErrorTracking.log_exception(e, extra_info)
      raise e
    end

    def self.try_get(path, options = {}, &block)
      self.get(path, options, &block)
    rescue *HTTP_ERRORS
      nil
    end
  end
end
