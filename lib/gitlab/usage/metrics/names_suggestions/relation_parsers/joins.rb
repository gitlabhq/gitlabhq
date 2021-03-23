# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module NamesSuggestions
        module RelationParsers
          class Joins < ::Arel::Visitors::PostgreSQL
            def accept(object)
              object.source.right.map do |join|
                visit(join, collector)
              end
            end

            private

            # rubocop:disable Naming/MethodName
            def visit_Arel_Nodes_StringJoin(object, collector)
              result = visit(object.left, collector)
              source, constraints = result.value.split('ON')
              {
                source: source.split('JOIN').last&.strip,
                constraints: constraints&.strip
              }.compact
            end

            def visit_Arel_Nodes_FullOuterJoin(object, _)
              parse_join(object)
            end

            def visit_Arel_Nodes_OuterJoin(object, _)
              parse_join(object)
            end

            def visit_Arel_Nodes_RightOuterJoin(object, _)
              parse_join(object)
            end

            def visit_Arel_Nodes_InnerJoin(object, _)
              {
                source: visit(object.left, collector).value,
                constraints: object.right ? visit(object.right.expr, collector).value : nil
              }.compact
            end
            # rubocop:enable Naming/MethodName

            def parse_join(object)
              {
                source: visit(object.left, collector).value,
                constraints: visit(object.right.expr, collector).value
              }
            end

            def quote(value)
              "#{value}"
            end

            def quote_table_name(name)
              "#{name}"
            end

            def quote_column_name(name)
              "#{name}"
            end

            def collector
              Arel::Collectors::SubstituteBinds.new(@connection, Arel::Collectors::SQLString.new)
            end
          end
        end
      end
    end
  end
end
