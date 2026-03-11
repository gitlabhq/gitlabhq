# frozen_string_literal: true

module Gitlab
  module Graphql
    class Variables
      # See lib/gitlab/middleware/json_validation.rb (`DEFAULT_LIMITS`) for matching limits
      PARSE_LIMITS = {
        max_depth: 32,
        max_array_size: 50000,
        max_hash_size: 50000,
        max_total_elements: 100000,
        # Disabled by default because some GraphQL queries upload large payloads
        max_json_size_bytes: 0
      }.freeze

      MAX_RECURSION_DEPTH = 3
      MAX_NESTED_STRING_SIZE = 10_000_000 # 10MB

      Invalid = Class.new(Gitlab::Graphql::StandardGraphqlError)

      def initialize(param, options = {})
        @param = param
        @parse_limits = options[:parse_limits] ? PARSE_LIMITS.merge(options[:parse_limits]) : PARSE_LIMITS
      end

      def to_h
        ensure_hash(@param)
      end

      private

      # Handle form data, JSON body, or a blank value
      def ensure_hash(ambiguous_param, depth = 0)
        case ambiguous_param
        when String
          if ambiguous_param.present?
            validate_nesting_depth!(depth)
            validate_nested_string_size!(ambiguous_param, depth)

            ensure_hash(parse_json(ambiguous_param), depth + 1)
          else
            {}
          end
        when Hash
          ambiguous_param
        when ActionController::Parameters
          # We can and have to trust the "Parameters" because `graphql-ruby` handles this hash safely
          # Also, `graphql-ruby` uses hash-specific methods, for example `size`:
          # https://sourcegraph.com/github.com/rmosolgo/graphql-ruby@61232b03412df6685406fc46c414e11d3f447817/-/blob/lib/graphql/query.rb?L304
          ambiguous_param.to_unsafe_h
        when nil
          {}
        else
          raise Invalid, "Unexpected parameter: #{ambiguous_param}"
        end
      end

      def validate_nesting_depth!(depth)
        raise Invalid, "Parameters nested too deeply" if depth > MAX_RECURSION_DEPTH
      end

      def validate_nested_string_size!(param, depth)
        raise Invalid, "Nested parameter too large" if depth > 0 && param.bytesize > MAX_NESTED_STRING_SIZE
      end

      def parse_json(user_input)
        Gitlab::Json.safe_parse(user_input, parse_limits: @parse_limits)
      rescue JSON::ParserError => ex
        raise Invalid, ex
      end
    end
  end
end
