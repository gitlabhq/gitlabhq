# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Sources
        class SequenceStructureSqlParser
          attr_reader :sequences

          def initialize(parsed_structure, default_schema_name)
            @parsed_structure = parsed_structure
            @default_schema_name = default_schema_name
            @sequences = {}
          end

          # Returns a map of sequence name to sequence structure objects
          def execute
            extract_sequences
            @sequences
          end

          private

          attr_reader :parsed_structure, :default_schema_name

          def extract_sequences
            parsed_structure.tree.stmts.each do |stmt|
              case stmt.stmt.node
              when :create_seq_stmt
                process_create_sequence(stmt.stmt.create_seq_stmt)
              when :alter_seq_stmt
                process_alter_sequence(stmt.stmt.alter_seq_stmt)
              when :alter_table_stmt
                process_alter_table(stmt.stmt.alter_table_stmt)
              end
            end
          end

          # Process CREATE SEQUENCE SQL queries. For example:
          #
          # CREATE SEQUENCE web_hook_logs_id_seq
          def process_create_sequence(create_seq)
            sequence_name = create_seq.sequence.relname
            schema_name = resolve_schema_name(create_seq.sequence.schemaname)
            full_name = "#{schema_name}.#{sequence_name}"

            @sequences[full_name] = ::Gitlab::Schema::Validation::Adapters::SequenceStructureSqlAdapter.new(
              sequence_name: sequence_name,
              schema_name: schema_name
            )
          end

          # Processes ALTER SEQUENCE SQL queries to extract column owner. For example:
          #
          # ALTER SEQUENCE ai_code_suggestion_events_id_seq OWNED BY ai_code_suggestion_events.id;
          def process_alter_sequence(alter_seq)
            sequence_schema = alter_seq.sequence.schemaname
            sequence_schema = default_schema_name if sequence_schema == ''
            sequence_name = alter_seq.sequence.relname

            # Look for OWNED BY option
            return unless alter_seq.options

            owner_schema = default_schema_name
            owner_table = nil
            owner_column = nil

            alter_seq.options.each do |option|
              def_elem = option.def_elem

              next unless def_elem.defname == 'owned_by'
              next unless def_elem.arg && def_elem.arg.node == :list

              owned_by_list = def_elem.arg.list.items

              next unless owned_by_list.length >= 2

              # Handle schema.table.column or table.column
              if owned_by_list.length == 3
                owner_schema = owned_by_list[0].string.sval
                owner_table = owned_by_list[1].string.sval
                owner_column = owned_by_list[2].string.sval
              else
                owner_table = owned_by_list[0].string.sval
                owner_column = owned_by_list[1].string.sval
              end
            end

            full_name = "#{sequence_schema}.#{sequence_name}"
            # Update or create sequence with ownership info
            existing = @sequences[full_name]

            unless existing
              warn "Could not find sequence #{full_name} for ALTER SEQUENCE command"
              return
            end

            existing.owner_table = owner_table
            existing.owner_column = owner_column
            existing.owner_schema = owner_schema
          end

          # Process ALTER TABLE commands to extract sequence owner. For example:
          #
          # ALTER TABLE ONLY web_hook_logs ALTER COLUMN id SET DEFAULT nextval('web_hook_logs_id_seq'::regclass);
          def process_alter_table(alter_table)
            table_name = alter_table.relation.relname
            table_schema = resolve_schema_name(alter_table.relation.schemaname)

            alter_table.cmds.each do |cmd|
              alter_cmd = cmd.alter_table_cmd

              # Look for SET DEFAULT nextval(...) commands
              next unless alter_cmd.subtype == :AT_ColumnDefault

              column_name = alter_cmd.name
              sequence_name = extract_sequence_from_default(alter_cmd.def)
              sequence_schema, sequence_name = process_sequence_name(sequence_name)
              lookup_name = "#{sequence_schema}.#{sequence_name}"

              # Update existing sequence or create new one
              existing = @sequences[lookup_name]

              @sequences[lookup_name] = ::Gitlab::Schema::Validation::Adapters::SequenceStructureSqlAdapter.new(
                sequence_name: sequence_name,
                schema_name: existing&.schema_name || table_schema,
                owner_table: existing&.owner_table || table_name,
                owner_column: existing&.owner_column || column_name,
                owner_schema: existing&.owner_schema || table_schema
              )
            end
          end

          def extract_sequence_from_default(expr)
            return nil unless expr

            case expr.node
            when :func_call
              func_call = expr.func_call
              return extract_string_from_expr(func_call.args.first) if nextval_func?(func_call)
            when :type_cast
              return extract_sequence_from_default(expr.type_cast.arg)
            end
            nil
          end

          def extract_string_from_expr(expr)
            case expr.node
            when :a_const
              expr.a_const.sval.sval if expr.a_const.val == :sval
            when :type_cast
              extract_string_from_expr(expr.type_cast.arg)
            end
          end

          def resolve_schema_name(schema_name)
            return default_schema_name if schema_name == ''

            schema_name
          end

          def process_sequence_name(sequence_name)
            data = sequence_name.split('.', 2)

            return default_schema_name, sequence_name if data.length == 1

            [data.first, data.last]
          end

          def nextval_func?(func_call)
            return false unless func_call.args.any?

            func_call.funcname.any? do |name|
              sval = name.string&.sval

              next false unless sval

              sval.casecmp('nextval').zero?
            end
          end
        end
      end
    end
  end
end
