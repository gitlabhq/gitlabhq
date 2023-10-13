# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Adapters
        UndefinedPGType = Class.new(StandardError)

        class ColumnStructureSqlAdapter
          NOT_NULL_CONSTR = :CONSTR_NOTNULL
          DEFAULT_CONSTR = :CONSTR_DEFAULT

          MAPPINGS = {
            't' => 'true',
            'f' => 'false'
          }.freeze

          attr_reader :table_name

          def initialize(table_name, pg_query_stmt, partitioning_stmt)
            @table_name = table_name
            @pg_query_stmt = pg_query_stmt
            @partitioning_stmt = partitioning_stmt
          end

          def name
            @name ||= pg_query_stmt.colname
          end

          def data_type
            type(pg_query_stmt.type_name)
          end

          def default
            return if name == 'id'

            value = parse_node(constraints.find { |node| node.constraint.contype == DEFAULT_CONSTR })

            return if value.nil?

            "DEFAULT #{value}"
          end

          def nullable
            'NOT NULL' if constraints.any? { |node| node.constraint.contype == NOT_NULL_CONSTR }
          end

          def partition_key?
            partition_keys.include?(name)
          end

          private

          attr_reader :pg_query_stmt, :partitioning_stmt

          def constraints
            @constraints ||= pg_query_stmt.constraints
          end

          # Returns the node type
          #
          # pg_type:: type alias, used internally by postgres, +int4+, +int8+, +bool+, +varchar+
          # type:: type name, like +integer+, +bigint+, +boolean+, +character varying+.
          # array_ext:: adds the +[]+ extension for array types.
          # precision_ext:: adds the precision, if have any, like +(255)+, +(6)+.
          #
          # @info +timestamp+ and +timestamptz+ have a particular case when precision is defined.
          #       In this case, the order of the statement needs to be re-arranged from
          #       timestamp without time zone(6) to timestamp(6) without a time zone.
          def type(node)
            pg_type = parse_node(node.names.last)
            type = PgTypes::TYPES.fetch(pg_type).dup
            array_ext = '[]' if node.array_bounds.any?
            precision_ext = "(#{node.typmods.map { |typmod| parse_node(typmod) }.join(',')})" if node.typmods.any?

            if %w[timestamp timestamptz].include?(pg_type)
              type.gsub!('timestamp', ['timestamp', precision_ext].compact.join)
              precision_ext = nil
            end

            [type, precision_ext, array_ext].compact.join
          rescue KeyError => e
            raise UndefinedPGType, e.message
          end

          # Parses PGQuery nodes recursively
          #
          # :constraint:: nodes that groups column default info
          # :partition_elem:: node that store partition key info
          # :func_cal:: nodes that stores functions, like +now()+
          # :a_const:: nodes that stores constant values, like +t+, +f+, +0.0.0.0+, +255+, +1.0+
          # :type_cast:: nodes that stores casting values, like +'name'::text+, +'0.0.0.0'::inet+
          # else:: extract node values in the last iteration of the recursion, like +int4+, +1.0+, +now+, +255+
          #
          # @note boolean types types are mapped from +t+, +f+ to +true+, +false+
          def parse_node(node)
            return unless node

            case node.node
            when :constraint
              parse_node(node.constraint.raw_expr)
            when :partition_elem
              node.partition_elem.name
            when :func_call
              "#{parse_node(node.func_call.funcname.first)}()"
            when :a_const
              parse_a_const(node.a_const)
            when :type_cast
              value = parse_node(node.type_cast.arg)
              type = type(node.type_cast.type_name)
              separator = MAPPINGS.key?(value) ? '' : "::#{type}"

              [MAPPINGS.fetch(value, "'#{value}'"), separator].compact.join
            else
              get_value_from_key(node, key: node.node)
            end
          end

          def parse_a_const(a_const)
            return unless a_const

            type = a_const.val
            get_value_from_key(a_const, key: type)
          end

          def get_value_from_key(node, key:)
            node.to_h[key].values.last
          end

          def partition_keys
            return [] unless partitioning_stmt

            @partition_keys ||= partitioning_stmt.part_params.map { |key_stmt| parse_node(key_stmt) }
          end
        end
      end
    end
  end
end
