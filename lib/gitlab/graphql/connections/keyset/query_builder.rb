# frozen_string_literal: true

module Gitlab
  module Graphql
    module Connections
      module Keyset
        class QueryBuilder
          def initialize(arel_table, order_list, decoded_cursor, before_or_after)
            @arel_table, @order_list, @decoded_cursor, @before_or_after = arel_table, order_list, decoded_cursor, before_or_after

            if order_list.empty?
              raise ArgumentError.new('No ordering scopes have been supplied')
            end
          end

          # Based on whether the main field we're ordering on is NULL in the
          # cursor, we can more easily target our query condition.
          # We assume that the last ordering field is unique, meaning
          # it will not contain NULLs.
          # We currently only support two ordering fields.
          #
          # Example of the conditions for
          #   relation: Issue.order(relative_position: :asc).order(id: :asc)
          #   after cursor: relative_position: 1500, id: 500
          #
          #   when cursor[relative_position] is not NULL
          #
          #       ("issues"."relative_position" > 1500)
          #       OR (
          #         "issues"."relative_position" = 1500
          #         AND
          #         "issues"."id" > 500
          #       )
          #       OR ("issues"."relative_position" IS NULL)
          #
          #   when cursor[relative_position] is NULL
          #
          #       "issues"."relative_position" IS NULL
          #       AND
          #       "issues"."id" > 500
          #
          def conditions
            attr_names  = order_list.map { |field| field.attribute_name }
            attr_values = attr_names.map { |name| decoded_cursor[name] }

            if attr_names.count == 1 && attr_values.first.nil?
              raise Gitlab::Graphql::Errors::ArgumentError.new('Before/after cursor invalid: `nil` was provided as only sortable value')
            end

            if attr_names.count == 1 || attr_values.first.present?
              Keyset::Conditions::NotNullCondition.new(arel_table, attr_names, attr_values, operators, before_or_after).build
            else
              Keyset::Conditions::NullCondition.new(arel_table, attr_names, attr_values, operators, before_or_after).build
            end
          end

          private

          attr_reader :arel_table, :order_list, :decoded_cursor, :before_or_after

          def operators
            order_list.map { |field| field.operator_for(before_or_after) }
          end
        end
      end
    end
  end
end
