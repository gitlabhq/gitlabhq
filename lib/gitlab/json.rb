# frozen_string_literal: true

module Gitlab
  module Json
    INVALID_LEGACY_TYPES = [String, TrueClass, FalseClass].freeze

    class << self
      def parse(string, *args, **named_args)
        legacy_mode = legacy_mode_enabled?(named_args.delete(:legacy_mode))
        data = adapter.parse(string, *args, **named_args)

        handle_legacy_mode!(data) if legacy_mode

        data
      end

      def parse!(string, *args, **named_args)
        legacy_mode = legacy_mode_enabled?(named_args.delete(:legacy_mode))
        data = adapter.parse!(string, *args, **named_args)

        handle_legacy_mode!(data) if legacy_mode

        data
      end

      def dump(*args)
        adapter.dump(*args)
      end

      def generate(*args)
        adapter.generate(*args)
      end

      def pretty_generate(*args)
        adapter.pretty_generate(*args)
      end

      private

      def adapter
        ::JSON
      end

      def parser_error
        ::JSON::ParserError
      end

      def legacy_mode_enabled?(arg_value)
        arg_value.nil? ? false : arg_value
      end

      def handle_legacy_mode!(data)
        return data unless Feature.enabled?(:json_wrapper_legacy_mode, default_enabled: true)

        raise parser_error if INVALID_LEGACY_TYPES.any? { |type| data.is_a?(type) }
      end
    end
  end
end
