# frozen_string_literal: true

require 'httparty'
require 'net/http'
require 'active_support/all'
require 'gitlab/utils/all'
require_relative 'new_connection_adapter'
require_relative 'exceptions'
require_relative 'lazy_response'

module Gitlab
  module HTTP_V2
    class Client
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

      connection_adapter NewConnectionAdapter

      class << self
        def try_get(path, options = {}, &block)
          self.get(path, options, &block) # rubocop:disable Style/RedundantSelf
        rescue *HTTP_ERRORS
          nil
        end

        def configuration
          Gitlab::HTTP_V2.configuration
        end

        private

        alias_method :httparty_perform_request, :perform_request

        # TODO: This overwrites a method implemented by `HTTPParty`
        # The calls to `get/...` will call this method instead of `httparty_perform_request`
        def perform_request(http_method, path, options, &block)
          raise_if_options_are_invalid(options)
          raise_if_blocked_by_silent_mode(http_method) if options.delete(:silent_mode_enabled)

          log_info = options.delete(:extra_log_info)
          async = options.delete(:async)

          options_with_timeouts =
            if !options.has_key?(:timeout)
              options.with_defaults(DEFAULT_TIMEOUT_OPTIONS)
            else
              options
            end

          if options[:stream_body]
            httparty_perform_request(http_method, path, options_with_timeouts, &block)
          elsif async
            async_perform_request(http_method, path, options, options_with_timeouts, log_info, &block)
          else
            sync_perform_request(http_method, path, options, options_with_timeouts, log_info, &block)
          end
        end

        def async_perform_request(http_method, path, options, options_with_timeouts, log_info, &block)
          start_time = nil
          read_total_timeout = options.fetch(:timeout, DEFAULT_READ_TOTAL_TIMEOUT)
          byte_size = 0
          max_bytesize = options.fetch(:max_bytes, 0)

          promise = Concurrent::Promise.new do
            Gitlab::Utils.restrict_within_concurrent_ruby do
              httparty_perform_request(http_method, path, options_with_timeouts) do |fragment|
                start_time ||= system_monotonic_time
                elapsed = system_monotonic_time - start_time
                byte_size += fragment.bytesize

                raise ReadTotalTimeout, "Request timed out after #{elapsed} seconds" if elapsed > read_total_timeout

                check_max_byte_size_limit!(max_bytesize, byte_size)

                yield fragment if block
              end
            end
          end

          LazyResponse.new(promise, path, options, log_info)
        end

        def sync_perform_request(http_method, path, options, options_with_timeouts, log_info, &block)
          start_time = nil
          read_total_timeout = options.fetch(:timeout, DEFAULT_READ_TOTAL_TIMEOUT)
          byte_size = 0
          max_bytesize = options.fetch(:max_bytes, 0)

          httparty_perform_request(http_method, path, options_with_timeouts) do |fragment|
            start_time ||= system_monotonic_time
            elapsed = system_monotonic_time - start_time
            byte_size += fragment.bytesize

            raise ReadTotalTimeout, "Request timed out after #{elapsed} seconds" if elapsed > read_total_timeout

            check_max_byte_size_limit!(max_bytesize, byte_size)

            yield fragment if block
          end
        rescue HTTParty::RedirectionTooDeep
          raise RedirectionTooDeep
        rescue *HTTP_ERRORS => e
          extra_info = log_info || {}
          extra_info = log_info.call(e, path, options) if log_info.respond_to?(:call)
          configuration.log_exception(e, extra_info)

          raise e
        end

        def raise_if_options_are_invalid(options)
          return unless options[:async] && (options[:stream_body] || options[:silent_mode_enabled])

          raise ArgumentError, '`async` cannot be used with `stream_body` or `silent_mode_enabled`'
        end

        def raise_if_blocked_by_silent_mode(http_method)
          return if SILENT_MODE_ALLOWED_METHODS.include?(http_method)

          configuration.silent_mode_log_info('Outbound HTTP request blocked', http_method.to_s)

          raise SilentModeBlockedError, 'only get, head, options, and trace methods are allowed in silent mode'
        end

        def check_max_byte_size_limit!(max_bytesize, byte_size)
          return unless max_bytesize > 0 && byte_size > max_bytesize

          configuration.log_with_level(:error,
            { message: 'Gitlab::HTTP - Response size too large', size: byte_size })

          raise ResponseSizeTooLarge, "Response size over #{max_bytesize} bytes"
        end

        def system_monotonic_time
          Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_second)
        end
      end
    end
  end
end
