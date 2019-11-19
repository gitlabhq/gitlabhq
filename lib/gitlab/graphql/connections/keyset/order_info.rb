# frozen_string_literal: true

module Gitlab
  module Graphql
    module Connections
      module Keyset
        class OrderInfo
          attr_reader :attribute_name, :sort_direction

          def initialize(order_value)
            if order_value.is_a?(String)
              @attribute_name, @sort_direction = extract_nulls_last_order(order_value)
            else
              @attribute_name = order_value.expr.name
              @sort_direction = order_value.direction
            end
          end

          def operator_for(before_or_after)
            case before_or_after
            when :before
              sort_direction == :asc ? '<' : '>'
            when :after
              sort_direction == :asc ? '>' : '<'
            end
          end

          # Only allow specific node types
          def self.build_order_list(relation)
            order_list = relation.order_values.select do |value|
              supported_order_value?(value)
            end

            order_list.map { |info| OrderInfo.new(info) }
          end

          def self.validate_ordering(relation, order_list)
            if order_list.empty?
              raise ArgumentError.new('A minimum of 1 ordering field is required')
            end

            if order_list.count > 2
              raise ArgumentError.new('A maximum of 2 ordering fields are allowed')
            end

            # make sure the last ordering field is non-nullable
            attribute_name = order_list.last&.attribute_name

            if relation.columns_hash[attribute_name].null
              raise ArgumentError.new("Column `#{attribute_name}` must not allow NULL")
            end

            if order_list.last.attribute_name != relation.primary_key
              raise ArgumentError.new("Last ordering field must be the primary key, `#{relation.primary_key}`")
            end
          end

          def self.supported_order_value?(order_value)
            return true if order_value.is_a?(Arel::Nodes::Ascending) || order_value.is_a?(Arel::Nodes::Descending)
            return false unless order_value.is_a?(String)

            tokens = order_value.downcase.split

            tokens.last(2) == %w(nulls last) && tokens.count == 4
          end

          private

          def extract_nulls_last_order(order_value)
            tokens = order_value.downcase.split

            [tokens.first, (tokens[1] == 'asc' ? :asc : :desc)]
          end
        end
      end
    end
  end
end
