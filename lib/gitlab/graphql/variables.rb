# frozen_string_literal: true

module Gitlab
  module Graphql
    class Variables
      Invalid = Class.new(Gitlab::Graphql::StandardGraphqlError)

      def initialize(param)
        @param = param
      end

      def to_h
        ensure_hash(@param)
      end

      private

      # Handle form data, JSON body, or a blank value
      def ensure_hash(ambiguous_param)
        case ambiguous_param
        when String
          if ambiguous_param.present?
            ensure_hash(Gitlab::Json.parse(ambiguous_param))
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
      rescue JSON::ParserError => e
        raise Invalid, e
      end
    end
  end
end
