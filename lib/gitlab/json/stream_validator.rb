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

      def sc_parse(body)
        @body_bytesize = body.bytesize

        if options[:max_json_size_bytes].to_i > 0 && body.bytesize > options[:max_json_size_bytes]
          raise BodySizeExceededError, "JSON body too large: #{body.bytesize} bytes"
        end

        ::Oj.sc_parse(self, body)
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
