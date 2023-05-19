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
    HeaderReadTimeout = Class.new(Net::ReadTimeout)
    SilentModeBlockedError = Class.new(StandardError)

    HTTP_TIMEOUT_ERRORS = [
      Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, Gitlab::HTTP::ReadTotalTimeout
    ].freeze
    HTTP_ERRORS = HTTP_TIMEOUT_ERRORS + [
      EOFError, SocketError, OpenSSL::SSL::SSLError, OpenSSL::OpenSSLError,
      Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH,
      Gitlab::HTTP::BlockedUrlError, Gitlab::HTTP::RedirectionTooDeep,
      Net::HTTPBadResponse
    ].freeze

    DEFAULT_TIMEOUT_OPTIONS = {
      open_timeout: 10,
      read_timeout: 20,
      write_timeout: 30
    }.freeze
    DEFAULT_READ_TOTAL_TIMEOUT = 30.seconds

    SILENT_MODE_ALLOWED_METHODS = [
      Net::HTTP::Get,
      Net::HTTP::Head,
      Net::HTTP::Options,
      Net::HTTP::Trace
    ].freeze

    include HTTParty # rubocop:disable Gitlab/HTTParty

    class << self
      alias_method :httparty_perform_request, :perform_request
    end

    connection_adapter HTTPConnectionAdapter

    def self.perform_request(http_method, path, options, &block)
      raise_if_blocked_by_silent_mode(http_method)

      log_info = options.delete(:extra_log_info)
      options_with_timeouts =
        if !options.has_key?(:timeout)
          options.with_defaults(DEFAULT_TIMEOUT_OPTIONS)
        else
          options
        end

      if options[:stream_body]
        return httparty_perform_request(http_method, path, options_with_timeouts, &block)
      end

      start_time = nil
      read_total_timeout = options.fetch(:timeout, DEFAULT_READ_TOTAL_TIMEOUT)

      httparty_perform_request(http_method, path, options_with_timeouts) do |fragment|
        start_time ||= Gitlab::Metrics::System.monotonic_time
        elapsed = Gitlab::Metrics::System.monotonic_time - start_time

        if elapsed > read_total_timeout
          raise ReadTotalTimeout, "Request timed out after #{elapsed} seconds"
        end

        yield fragment if block
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

    def self.raise_if_blocked_by_silent_mode(http_method)
      return unless blocked_by_silent_mode?(http_method)

      ::Gitlab::SilentMode.log_info(
        message: 'Outbound HTTP request blocked',
        outbound_http_request_method: http_method.to_s
      )

      raise SilentModeBlockedError, 'only get, head, options, and trace methods are allowed in silent mode'
    end

    def self.blocked_by_silent_mode?(http_method)
      ::Gitlab::SilentMode.enabled? && SILENT_MODE_ALLOWED_METHODS.exclude?(http_method)
    end
  end
end
