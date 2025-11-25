# frozen_string_literal: true

module Gitlab
  module Json
    # See https://www.rubydoc.info/gems/oj/Oj/ScHandler for required methods
    class StreamValidator < ::Oj::ScHandler
      LimitExceededError = Class.new(StandardError)
      DepthLimitError = Class.new(LimitExceededError)
      ArraySizeLimitError = Class.new(LimitExceededError)
      ElementCountLimitError = Class.new(LimitExceededError)
      HashSizeLimitError = Class.new(LimitExceededError)
      BodySizeExceededError = Class.new(LimitExceededError)

      # Match integers, floats, and scientific notation with reasonable size limits
      # Supports: 123, -123, 12.3, -12.3, 1.23e10, -1.23E-10
      # Limits: max 15 digits for integer part, max 15 digits for fractional part, max 3 digits for exponent
      NUMERIC_REGEX = /\A[+-]?(?:\d{1,15}\.?\d{0,15}|\.\d{1,15})(?:[eE][+-]?\d{1,3})?\z/

      attr_reader :result, :options

      # We want to hide the limits configured, but still show what type
      def self.user_facing_error_message(exception)
        case exception
        when ::Gitlab::Json::StreamValidator::DepthLimitError
          "Parameters nested too deeply"
        when ::Gitlab::Json::StreamValidator::ArraySizeLimitError
          "Array parameter too large"
        when ::Gitlab::Json::StreamValidator::HashSizeLimitError
          "Hash parameter too large"
        when ::Gitlab::Json::StreamValidator::ElementCountLimitError
          "Too many total parameters"
        when ::Gitlab::Json::StreamValidator::BodySizeExceededError
          "JSON body too large"
        else
          "Invalid JSON: limit exceeded"
        end
      end

      def initialize(options)
        @options = options
        @depth = 0
        @array_counts = {} # Track size by array object_id
        @hash_counts = {} # Track size by hash object_id
        @body_bytesize = 0
        @total_elements = 0
        @stack = []
        @result = nil
        @max_depth_reached = 0
        @max_array_count = 0
        @max_hash_count = 0
      end

      # This method validates the JSON input against configured size limits.
      # It uses Oj's streaming parser for efficient processing of large JSON
      # documents while enforcing safety limits.
      #
      # @param body [String] the JSON string to parse
      # @return [nil] returns nil after successful validation or when skipping primitive values
      # @raise [Oj::ParseError] when the JSON is malformed or invalid
      # @raise [EncodingError] when the JSON is malformed or invalid
      # @raise [::Gitlab::Json::StreamValidator::LimitExceededError] when parsing limits (depth, array size, etc.)
      # are exceeded
      #
      # @example Parse a simple JSON string
      #   validator = Gitlab::Json::StreamValidator.new(max_json_size_bytes: 1024)
      #   validator.validate!('{"key": "value"}') #=> nil
      #
      # @example Handle size limit exceeded
      #   validator = Gitlab::Json::StreamValidator.new(max_json_size_bytes: 10)
      #   validator.validate!('{"very": "long json string"}')
      #   # raises BodySizeExceededError
      def validate!(body)
        return if body.nil? || body.empty?

        @body_bytesize = body.bytesize

        check_body_size!

        # Oj.sc_parse does not handle primitive values (see https://github.com/ohler55/oj/issues/979)
        # so we need to handle them separately before calling the streaming parser
        return if %w[true false null].include?(body)
        return if quoted_string?(body)
        return if body.encoding == Encoding::UTF_8 && body.valid_encoding? && NUMERIC_REGEX.match?(body)

        ::Oj.sc_parse(self, body)

        nil
      end

      # Called when a hash starts
      def hash_start
        check_depth!
        @depth += 1
        @max_depth_reached = [@max_depth_reached, @depth].max

        hash = {}
        @hash_counts[hash.object_id] = 0 # rubocop:disable Lint/HashCompareByIdentity -- We want to track by object ID
        @stack.push(hash)
        hash
      end

      # Called when a hash ends
      def hash_end
        @depth -= 1
        hash = @stack.pop
        @hash_counts.delete(hash.object_id)

        @result = hash if @stack.empty?

        hash
      end

      # Called for each key in a hash
      def hash_key(key)
        increment_element_count!

        key
      end

      # Called when a key/value pair is complete
      def hash_set(hash, key, value)
        increment_element_count!

        current_size = @hash_counts[hash.object_id] || 0 # rubocop:disable Lint/HashCompareByIdentity -- We want to track by object ID
        check_hash_size!(current_size)

        hash[key] = value
        new_size = current_size + 1
        @hash_counts[hash.object_id] = new_size # rubocop:disable Lint/HashCompareByIdentity -- We want to track by object ID
        @max_hash_count = [@max_hash_count, new_size].max
      end

      # Called when an array starts
      def array_start
        check_depth!
        @depth += 1
        @max_depth_reached = [@max_depth_reached, @depth].max

        array = []
        @array_counts[array.object_id] = 0 # rubocop:disable Lint/HashCompareByIdentity -- We want to track by object ID
        @stack.push(array)
        array
      end

      # Called when an array ends
      def array_end
        @depth -= 1
        array = @stack.pop
        @array_counts.delete(array.object_id)

        @result = array if @stack.empty?

        array
      end

      def array_append(array, value)
        increment_element_count!

        current_size = @array_counts[array.object_id] || 0 # rubocop:disable Lint/HashCompareByIdentity -- We want to track by object ID

        check_array_size!(current_size)

        array << value
        new_size = current_size + 1
        @array_counts[array.object_id] = new_size # rubocop:disable Lint/HashCompareByIdentity -- We want to track by object ID
        @max_array_count = [@max_array_count, new_size].max
      end

      # Called for root values (when not in a hash or array)
      def add_value(value)
        increment_element_count!
        @result = value
      end

      # Returns metadata about the parsed JSON structure
      def metadata
        {
          body_bytesize: @body_bytesize,
          total_elements: @total_elements,
          max_array_count: @max_array_count,
          max_hash_count: @max_hash_count,
          max_depth: @max_depth_reached
        }
      end

      private

      def quoted_string?(body)
        return false if body.nil? || body.length < 2

        body.start_with?('"') && body.end_with?('"')
      end

      def check_body_size!
        return unless options[:max_json_size_bytes].to_i > 0
        return unless @body_bytesize
        return unless @body_bytesize > options[:max_json_size_bytes]

        raise BodySizeExceededError, "JSON body too large: #{@body_bytesize} bytes"
      end

      def check_depth!
        return unless options[:max_depth].to_i > 0
        return unless @depth >= options[:max_depth]

        raise DepthLimitError,
          "JSON depth #{@depth + 1} exceeds limit of #{options[:max_depth]}"
      end

      def check_array_size!(current_size)
        return unless options[:max_array_size].to_i > 0

        return unless current_size >= options[:max_array_size]

        raise ArraySizeLimitError,
          "Array size exceeds limit of #{options[:max_array_size]} (tried to add element #{current_size + 1})"
      end

      def check_hash_size!(current_size)
        return unless options[:max_hash_size].to_i > 0

        return unless current_size >= options[:max_hash_size]

        raise HashSizeLimitError,
          "Hash size exceeds limit of #{options[:max_hash_size]} (tried to add key-value pair #{current_size + 1})"
      end

      def check_element_size!
        return unless options[:max_total_elements].to_i > 0
        return unless @total_elements >= options[:max_total_elements]

        raise ElementCountLimitError,
          "Total elements (#{@total_elements}) exceeds limit of #{options[:max_total_elements]}"
      end

      def increment_element_count!
        @total_elements += 1
        check_element_size!
      end
    end
  end
end
