# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module NamesSuggestions
        module RelationParsers
          class Constraints < ::Arel::Visitors::PostgreSQL
            # rubocop:disable Naming/MethodName
            def visit_Arel_Nodes_SelectCore(object, collector)
              collect_nodes_for(object.wheres, collector, "") || collector
            end
            # rubocop:enable Naming/MethodName

            def quote(value)
              "#{value}"
            end

            def quote_table_name(name)
              "#{name}"
            end

            def quote_column_name(name)
              "#{name}"
            end
          end
        end
      end
    end
  end
end
