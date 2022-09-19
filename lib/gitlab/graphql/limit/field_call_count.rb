# frozen_string_literal: true

module Gitlab
  module Graphql
    module Limit
      class FieldCallCount < ::GraphQL::Schema::FieldExtension
        def resolve(object:, arguments:, context:)
          raise Gitlab::Graphql::Errors::ArgumentError, 'Limit must be specified.' unless limit
          raise Gitlab::Graphql::Errors::LimitError, error_message if increment_call_count(context) > limit

          yield(object, arguments)
        end

        private

        def increment_call_count(context)
          context[:call_count] ||= {}
          context[:call_count][field] ||= 0
          context[:call_count][field] += 1
        end

        def limit
          options[:limit]
        end

        def error_message
          "\"#{field.graphql_name}\" field can be requested only for #{limit} #{field.owner.graphql_name}(s) at a time."
        end
      end
    end
  end
end
