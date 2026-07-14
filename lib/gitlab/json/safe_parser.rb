# frozen_string_literal: true

# `SafeParser` provides a thin wrapper around `Oj::Safe` that enforces limits on
# JSON parsing and converts low-level parsing errors into user-facing,
# human-readable error messages.
#
# The parser validates incoming JSON payloads against a configurable set of
# limits (such as maximum depth, array size, hash size, total element count,
# and payload size). If a payload violates one of these limits, the underlying
# Oj::Safe error is mapped to a more descriptive message before being raised.
#
#
# Thread Safety
# -------------
#
# The underlying `Oj::Safe` parser instance is not thread-safe. To prevent
# concurrent access from multiple threads, each `SafeParser` instance records
# the owner thread and enforces thread affinity. Any attempt to use the parser
# from a different thread raises `ConcurrencyError`.
#
# This is a defensive guardrail to avoid undefined behavior in the native
# extension. `SafeParser` instances should therefore be treated as
# single-thread-owned objects.
#
#
# Configuration
# -------------
#
# Only a predefined set of parsing limits is allowed. Unknown configuration
# keys will raise UnknownConfigurationError during initialization.
#
# Available configuration options are;
#
# - `max_hash_size`: Maximum number of key/value pairs allowed in a JSON object.
# - `max_array_size`: Maximum number of items allowed in a JSON array.
# - `max_depth`: Maximum nesting depth allowed.
# - `max_total_elements`: Maximum total number of parsed elements.
# - `max_json_size_bytes`: Maximum size of the input JSON string in bytes.
#
#
# Usage
# -----
#
# parser = Gitlab::Json::SafeParser.new(max_array_size: 1)
#
# parser.parse('[1]') # => [1]
# parser.parse('[1, 2]') # => JSON::ParserError: Array parameter too large
#
#
# Error Handling
# --------------
#
# Encoding errors and Oj::Safe validation errors are converted into
# `JSON::ParserError` errors with human-readable messages to provide
# consistent error reporting to callers.
#
module Gitlab
  module Json
    class SafeParser
      class UnknownConfigurationError < RuntimeError
        def initialize(configuration_keys)
          super <<~MSG
            Unknown configuration options provided: #{configuration_keys.join(', ')}
          MSG
        end
      end

      class ConcurrencyError < RuntimeError
        def initialize
          super('SafeParser is being used by a different thread!')
        end
      end

      PayloadSizeError = Class.new(RuntimeError)

      THREAD_CACHE_NAMESPACE = 'safe-parser-instances'

      ERRORS = {
        Oj::Parser::DepthError => 'Parameters nested too deeply',
        Oj::Parser::ArraySizeError => 'Array parameter too large',
        Oj::Parser::HashSizeError => 'Hash parameter too large',
        Oj::Parser::TotalElementsError => 'Too many total parameters',
        PayloadSizeError => 'JSON body too large'
      }.freeze

      class << self
        def humanize_error(error)
          ERRORS.fetch(error.class, error.message)
        end

        def valid_option_keys
          @valid_option_keys ||= PARSE_LIMITS.keys
        end

        def parse(payload, **options)
          instance(options).parse(payload)
        end

        private

        # Returns a thread-local `SafeParser` instance for the given options.
        #
        # Options are merged with `PARSE_LIMITS`, and the resulting effective limits are
        # used as the cache key. Calls from the same thread with the same limits reuse
        # the same parser instance.
        #
        # A different thread always gets a different instance because `Oj::Parser.safe`
        # is not thread-safe.
        def instance(options)
          parse_limits = PARSE_LIMITS.merge(options)

          instance_for(parse_limits)
        end

        def instance_for(options)
          Thread.current[THREAD_CACHE_NAMESPACE] ||= {}
          Thread.current[THREAD_CACHE_NAMESPACE][options] ||= new(**options)
        end
      end

      def initialize(**options)
        @parse_limits = PARSE_LIMITS.merge(options)

        validate_options!

        @oj_safe = Oj::Parser.safe(@parse_limits)
        @owner_thread = Thread.current
      end

      def parse(payload)
        validate_thread!
        validate_payload_size!(payload)

        oj_safe.parse(payload)
      rescue EncodingError, PayloadSizeError, Oj::Parser::ValidationError => error
        raise_human_readable_error!(error)
      end

      private

      attr_reader :oj_safe, :parse_limits, :owner_thread

      delegate :valid_option_keys, to: :'self.class'

      # Ensures this parser instance is used only by the thread that created it.
      #
      # `Oj::Parser.safe` is not thread-safe and keeps parsing state in native heap memory,
      # so cross-thread access can lead to undefined behavior.
      #
      # Raises `ConcurrencyError` when called from a different thread.
      def validate_thread!
        raise ConcurrencyError unless same_thread?
      end

      def same_thread?
        owner_thread == Thread.current
      end

      def validate_payload_size!(payload)
        return unless parse_limits[:max_json_size_bytes]
        return unless payload.bytesize > parse_limits[:max_json_size_bytes]

        raise PayloadSizeError
      end

      def raise_human_readable_error!(error)
        message = self.class.humanize_error(error)

        raise Gitlab::Json.parser_error, message
      end

      def validate_options!
        extra_keys = parse_limits.keys - valid_option_keys

        return unless extra_keys.any?

        raise UnknownConfigurationError, extra_keys
      end
    end
  end
end
