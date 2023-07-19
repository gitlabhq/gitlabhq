# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Sources
        class StructureSql
          DEFAULT_SCHEMA = 'public'

          def initialize(structure_file_path, schema_name = DEFAULT_SCHEMA)
            @structure_file_path = structure_file_path
            @schema_name = schema_name
          end

          def index_exists?(index_name)
            index = indexes.find { |index| index.name == index_name }

            return false if index.nil?

            true
          end

          def trigger_exists?(trigger_name)
            trigger = triggers.find { |trigger| trigger.name == trigger_name }

            return false if trigger.nil?

            true
          end

          def foreign_key_exists?(foreign_key_name)
            foreign_key = foreign_keys.find { |fk| fk.name == foreign_key_name }

            return false if foreign_key.nil?

            true
          end

          def table_exists?(table_name)
            table = fetch_table_by_name(table_name)

            return false if table.nil?

            true
          end

          def fetch_table_by_name(table_name)
            tables.find { |table| table.name == table_name }
          end

          def indexes
            @indexes ||= map_with_default_schema(index_statements, SchemaObjects::Index)
          end

          def triggers
            @triggers ||= map_with_default_schema(trigger_statements, SchemaObjects::Trigger)
          end

          def foreign_keys
            @foreign_keys ||= foreign_key_statements.map do |stmt|
              stmt.relation.schemaname = schema_name if stmt.relation.schemaname == ''

              SchemaObjects::ForeignKey.new(Adapters::ForeignKeyStructureSqlAdapter.new(stmt))
            end
          end

          def tables
            @tables ||= table_statements.map do |stmt|
              table_name = stmt.relation.relname
              partition_stmt = stmt.partspec

              columns = stmt.table_elts.select { |n| n.node == :column_def }.map do |column|
                adapter = Adapters::ColumnStructureSqlAdapter.new(table_name, column.column_def, partition_stmt)
                SchemaObjects::Column.new(adapter)
              end

              SchemaObjects::Table.new(table_name, columns)
            end
          end

          private

          attr_reader :structure_file_path, :schema_name

          def index_statements
            statements.filter_map { |s| s.stmt.index_stmt }
          end

          def trigger_statements
            statements.filter_map { |s| s.stmt.create_trig_stmt }
          end

          def table_statements
            statements.filter_map { |s| s.stmt.create_stmt }
          end

          def foreign_key_statements
            constraint_statements(:CONSTR_FOREIGN)
          end

          # Filter constraint statement nodes
          #
          # @param constraint_type [Symbol] node type. One of CONSTR_PRIMARY, CONSTR_CHECK, CONSTR_EXCLUSION,
          #        CONSTR_UNIQUE or CONSTR_FOREIGN.
          def constraint_statements(constraint_type)
            alter_table_statements(:AT_AddConstraint).filter do |stmt|
              stmt.cmds.first.alter_table_cmd.def.constraint.contype == constraint_type
            end
          end

          # Filter alter table statement nodes
          #
          # @param subtype [Symbol] node subtype +AT_AttachPartition+, +AT_ColumnDefault+ or +AT_AddConstraint+
          def alter_table_statements(subtype)
            statements.filter_map do |statement|
              node = statement.stmt.alter_table_stmt

              next unless node

              node if node.cmds.first.alter_table_cmd.subtype == subtype
            end
          end

          def statements
            @statements ||= parsed_structure_file.tree.stmts
          end

          def parsed_structure_file
            PgQuery.parse(File.read(structure_file_path))
          end

          def map_with_default_schema(statements, validation_class)
            statements.map do |statement|
              statement.relation.schemaname = schema_name if statement.relation.schemaname == ''

              validation_class.new(statement)
            end
          end
        end
      end
    end
  end
end
