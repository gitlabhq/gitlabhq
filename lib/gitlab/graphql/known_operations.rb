# frozen_string_literal: true

module Gitlab
  module Graphql
    class KnownOperations
      Operation = Struct.new(:name, :metadata) do
        def to_caller_id
          "graphql:#{name}"
        end

        def feature_category
          metadata&.dig('feature_category')
        end

        def query_urgency
          urgency_name = metadata&.dig('urgency')
          return ::Gitlab::EndpointAttributes::DEFAULT_URGENCY unless urgency_name

          ::Gitlab::EndpointAttributes::Config::REQUEST_URGENCIES[urgency_name.to_sym] ||
            ::Gitlab::EndpointAttributes::DEFAULT_URGENCY
        end
      end

      UNKNOWN = Operation.new("unknown", {}).freeze

      def self.default
        @default ||= self.new(Gitlab::Webpack::GraphqlKnownOperations.load)
      end

      def initialize(operation_data)
        @operation_hash = operation_data
                            .map { |name, metadata| Operation.new(name, metadata).freeze }
                            .concat([UNKNOWN])
                            .index_by(&:name)
      end

      # Returns the known operation from the given ::GraphQL::Query object
      def from_query(query)
        operation_name = query.selected_operation_name

        return UNKNOWN unless operation_name

        @operation_hash[operation_name] || UNKNOWN
      end

      def operations
        @operation_hash.values
      end
    end
  end
end
