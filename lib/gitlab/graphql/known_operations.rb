# frozen_string_literal: true

module Gitlab
  module Graphql
    class KnownOperations
      Operation = Struct.new(:name) do
        def to_caller_id
          "graphql:#{name}"
        end

        def query_urgency
          # We'll be able to actually correlate query_urgency with https://gitlab.com/gitlab-org/gitlab/-/issues/345141
          ::Gitlab::EndpointAttributes::DEFAULT_URGENCY
        end
      end

      UNKNOWN = Operation.new("unknown").freeze

      def self.default
        @default ||= self.new(Gitlab::Webpack::GraphqlKnownOperations.load)
      end

      def initialize(operation_names)
        @operation_hash = operation_names
          .map { |name| Operation.new(name).freeze }
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
