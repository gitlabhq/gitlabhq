# frozen_string_literal: true

module Gitlab
  module Database
    module DataIsolation
      module Strategies
        module Arel
          class Scope
            def add_scope(ast)
              return ast if Context.disabled?

              scoped_ast = ast.dup

              from_tables = extract_from_tables(scoped_ast)

              from_tables.each do |table_name|
                keys = sharding_key_entry(table_name)
                next unless keys

                condition = build_condition(table_name, keys)
                next unless condition

                scoped_ast.where(condition)
              end

              scoped_ast
            end

            private

            def sharding_key_entry(table_name)
              Gitlab::Database::DataIsolation.configuration.sharding_key_map[table_name]
            end

            def build_condition(table_name, keys)
              table = ::Arel::Table.new(table_name)

              conditions = keys.filter_map do |column, type|
                value = resolve_value(type)
                next unless value

                build_column_condition(table, column, value)
              end

              return if conditions.empty?

              conditions.reduce { |acc, cond| acc.or(cond) }
            end

            def build_column_condition(table, column, value)
              if value.is_a?(::ActiveRecord::Relation)
                table[column].in(value.arel)
              else
                table[column].eq(value)
              end
            end

            def resolve_value(type)
              Gitlab::Database::DataIsolation.configuration.current_sharding_key_value.call(type)
            end

            def extract_from_tables(ast)
              tables = []

              ast.froms&.each do |from|
                table_name = extract_table_name(from)
                tables << table_name if table_name
              end

              tables.uniq
            end

            def extract_table_name(node)
              case node
              when ::Arel::Table
                node.name
              when ::Arel::Nodes::TableAlias, ::Arel::Nodes::JoinSource
                extract_table_name(node.left)
              end
            end
          end
        end
      end
    end
  end
end
