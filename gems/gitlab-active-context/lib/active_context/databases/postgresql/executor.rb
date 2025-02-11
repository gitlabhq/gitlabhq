# frozen_string_literal: true

module ActiveContext
  module Databases
    module Postgresql
      class Executor
        include ActiveContext::Databases::Concerns::Executor

        private

        def do_create_collection(name:, number_of_partitions:, fields:)
          strategy = PartitionStrategy.new(
            name: name,
            number_of_partitions: number_of_partitions
          )

          return if collection_exists?(strategy)

          # Create parent table if it doesn't exist
          create_parent_table(strategy.collection_name, fields) unless table_exists?(strategy.collection_name)

          # Create child partition tables
          strategy.each_partition do |partition_name|
            next if table_exists?(partition_name)

            create_partition_table(
              partition_name,
              strategy.collection_name,
              get_partition_remainder(partition_name)
            )
          end

          # Create indices on fields that need them
          create_indices(strategy, fields)
        end

        def create_parent_table(name, fields)
          fixed_columns, variable_columns = sort_fields_by_size(fields)

          adapter.client.with_connection do |connection|
            connection.create_table(name, id: false, primary_key: [:id, :partition_id],
              options: 'PARTITION BY LIST (partition_id)') do |table|
              # Add partition_id first as it's required for partitioning
              table.integer :partition_id, null: false

              # Add fixed columns first for better memory alignment
              fixed_columns.each do |field|
                add_column_from_field(table, field)
              end

              # Add id column
              table.string :id, null: false

              # Add variable width columns last
              variable_columns.each do |field|
                add_column_from_field(table, field)
              end
            end
          end
        end

        def sort_fields_by_size(fields)
          fixed_columns = []
          variable_columns = []

          fields.each do |field|
            case field
            when Field::Vector
              # Vector fields have fixed size based on dimensions
              fixed_columns << [field, field.options[:dimensions] * 4]
            when Field::Bigint
              # Bigint is 8 bytes
              fixed_columns << [field, 8]
            when Field::Prefix
              # Text fields are variable width
              variable_columns << field
            else
              raise ArgumentError, "Unknown field type: #{field.class}"
            end
          end

          # Sort fixed-size columns by size in descending order for best alignment
          [fixed_columns.sort_by { |_, size| -size }.map(&:first), variable_columns]
        end

        def add_column_from_field(table, field)
          case field
          when Field::Vector
            table.column(field.name, "vector(#{field.options[:dimensions]})")
          when Field::Bigint
            table.bigint(field.name, **field.options.except(:index))
          when Field::Prefix
            table.text(field.name, **field.options.except(:index))
          else
            raise ArgumentError, "Unknown field type: #{field.class}"
          end
        end

        def add_column_from_definition(table, column_def, _connection)
          name, type_info = parse_column_definition(column_def)

          if type_info[:type] == :virtual
            # For vector columns, use raw SQL type
            table.column(name, type_info[:options][:as])
          else
            table.column(name, type_info[:type], **type_info[:options])
          end
        end

        def create_partition_table(partition_name, parent_name, partition_id)
          adapter.client.with_connection do |connection|
            sql = <<~SQL.squish
              CREATE TABLE #{connection.quote_table_name(partition_name)}
              PARTITION OF #{connection.quote_table_name(parent_name)}
              FOR VALUES IN (#{partition_id});
            SQL

            connection.execute(sql)
          end
        end

        def create_indices(strategy, fields)
          fields.each do |field|
            next unless field.options[:index]

            if field.is_a?(Field::Vector)
              strategy.each_partition do |partition_name|
                next if index_exists?(partition_name, field)

                create_vector_index(partition_name, field)
              end
            else
              create_standard_index(strategy.collection_name, field)
            end
          end
        end

        def create_standard_index(table_name, field)
          adapter.client.with_connection do |connection|
            next if index_exists?(table_name, field)

            connection.add_index(
              table_name,
              field.name,
              name: index_name_for(table_name, field)
            )
          end
        end

        def create_vector_index(table_name, field)
          adapter.client.with_connection do |connection|
            next if index_exists?(table_name, field)

            index_name = index_name_for(table_name, field)

            connection.execute(<<~SQL.squish)
              CREATE INDEX #{connection.quote_column_name(index_name)}
              ON #{connection.quote_table_name(table_name)}
              USING hnsw (#{connection.quote_column_name(field.name)} vector_l2_ops)
            SQL
          end
        end

        def index_exists?(table_name, field)
          adapter.client.with_connection do |connection|
            index_name = index_name_for(table_name, field)
            connection.index_exists?(table_name, field.name, name: index_name)
          end
        end

        def index_name_for(table_name, field)
          "#{table_name}_#{field.name}_idx"
        end

        def collection_exists?(strategy)
          adapter.client.with_connection do |connection|
            exists = connection.table_exists?(strategy.collection_name)
            next false unless exists

            strategy.partition_names.all? do |partition_name|
              connection.table_exists?(partition_name)
            end
          end
        end

        def table_exists?(name)
          adapter.client.with_connection do |connection|
            connection.table_exists?(name)
          end
        end

        def get_partition_remainder(partition_name)
          partition_name.split('_').last.to_i
        end
      end
    end
  end
end
