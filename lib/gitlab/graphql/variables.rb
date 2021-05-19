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
        when Hash, ActionController::Parameters
          ambiguous_param
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
