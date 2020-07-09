# frozen_string_literal: true

# This is a GitLab-specific JSON interface. You should use this instead
# of using `JSON` directly. This allows us to swap the adapter and handle
# legacy issues.

module Gitlab
  module Json
    INVALID_LEGACY_TYPES = [String, TrueClass, FalseClass].freeze

    class << self
      # Parse a string and convert it to a Ruby object
      #
      # @param string [String] the JSON string to convert to Ruby objects
      # @param opts [Hash] an options hash in the standard JSON gem format
      # @return [Boolean, String, Array, Hash]
      # @raise [JSON::ParserError] raised if parsing fails
      def parse(string, opts = {})
        # First we should ensure this really is a string, not some other
        # type which purports to be a string. This handles some legacy
        # usage of the JSON class.
        string = string.to_s unless string.is_a?(String)

        legacy_mode = legacy_mode_enabled?(opts.delete(:legacy_mode))
        data = adapter_load(string, opts)

        handle_legacy_mode!(data) if legacy_mode

        data
      end

      alias_method :parse!, :parse

      # Take a Ruby object and convert it to a string
      #
      # @param object [Boolean, String, Array, Hash, Object] depending on the adapter this can be a variety of types
      # @param opts [Hash] an options hash in the standard JSON gem format
      # @return [String]
      def dump(object, opts = {})
        adapter_dump(object, opts)
      end

      # Legacy method used in our codebase that might just be an alias for `parse`.
      # Will be updated to use our `parse` method.
      def generate(*args)
        ::JSON.generate(*args)
      end

      # Generates a JSON string and formats it nicely.
      # Varies depending on adapter and will be updated to use our methods.
      def pretty_generate(*args)
        ::JSON.pretty_generate(*args)
      end

      private

      # Convert JSON string into Ruby through toggleable adapters.
      #
      # Must rescue adapter-specific errors and return `parser_error`, and
      # must also standardize the options hash to support each adapter as
      # they all take different options.
      #
      # @param string [String] the JSON string to convert to Ruby objects
      # @param opts [Hash] an options hash in the standard JSON gem format
      # @return [Boolean, String, Array, Hash]
      # @raise [JSON::ParserError]
      def adapter_load(string, opts = {})
        opts = standardize_opts(opts)

        if enable_oj?
          Oj.load(string, opts)
        else
          ::JSON.parse(string, opts)
        end
      rescue Oj::ParseError, Encoding::UndefinedConversionError => ex
        raise parser_error.new(ex)
      end

      # Convert Ruby object to JSON string through toggleable adapters.
      #
      # @param object [Boolean, String, Array, Hash, Object] depending on the adapter this can be a variety of types
      # @param opts [Hash] an options hash in the standard JSON gem format
      # @return [String]
      def adapter_dump(thing, opts = {})
        opts = standardize_opts(opts)

        if enable_oj?
          Oj.dump(thing, opts)
        else
          ::JSON.dump(thing, opts)
        end
      end

      # Take a JSON standard options hash and standardize it to work across adapters
      # An example of this is Oj taking :symbol_keys instead of :symbolize_names
      #
      # @param opts [Hash]
      # @return [Hash]
      def standardize_opts(opts = {})
        if enable_oj?
          opts[:mode] = :rails
          opts[:symbol_keys] = opts[:symbolize_keys] || opts[:symbolize_names]
        end

        opts
      end

      # The standard parser error we should be returning. Defined in a method
      # so we can potentially override it later.
      #
      # @return [JSON::ParserError]
      def parser_error
        ::JSON::ParserError
      end

      # @param [Nil, Boolean] an extracted :legacy_mode key from the opts hash
      # @return [Boolean]
      def legacy_mode_enabled?(arg_value)
        arg_value.nil? ? false : arg_value
      end

      # If legacy mode is enabled, we need to raise an error depending on the values
      # provided in the string. This will be deprecated.
      #
      # @param data [Boolean, String, Array, Hash, Object]
      # @return [Boolean, String, Array, Hash, Object]
      # @raise [JSON::ParserError]
      def handle_legacy_mode!(data)
        return data unless Feature.enabled?(:json_wrapper_legacy_mode, default_enabled: true)

        raise parser_error if INVALID_LEGACY_TYPES.any? { |type| data.is_a?(type) }
      end

      # @return [Boolean]
      def enable_oj?
        Feature.enabled?(:oj_json, default_enabled: true)
      end
    end
  end
end
