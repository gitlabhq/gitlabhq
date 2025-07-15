# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Adapters
        class SequenceDatabaseAdapter
          def initialize(query_result)
            @query_result = query_result
          end

          def name
            return unless query_result['sequence_name']

            "#{schema}.#{query_result['sequence_name']}"
          end

          def column_owner
            return unless query_result['owned_by_column']

            "#{schema}.#{query_result['owned_by_column']}"
          end

          def user_owner
            query_result['user_owner']
          end

          def start_value
            query_result['start_value']
          end

          def increment_by
            query_result['increment_by']
          end

          def min_value
            query_result['min_value']
          end

          def max_value
            query_result['max_value']
          end

          def cycle
            query_result['cycle']
          end

          private

          attr_reader :query_result

          def schema
            query_result['schema'] || 'public'
          end
        end
      end
    end
  end
end
