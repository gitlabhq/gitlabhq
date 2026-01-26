# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module ConvertToBigint
        INDEX_OPTIONS_MAP = {
          unique: :unique,
          order: :orders,
          opclass: :opclasses,
          where: :where,
          type: :type,
          using: :using,
          comment: :comment
        }.freeze

        # Acts as ActiveRecord::ConnectionAdapters::IndexDefinition when
        # creating bigint indexes for primary key at #create_primary_key_index method
        PkIndexDefinition = Struct.new(:name, :unique, :columns, keyword_init: true) do
          def as_json(*)
            to_h.stringify_keys
          end
        end

        def com_or_dev_or_test_but_not_jh?
          return true if Gitlab.dev_or_test_env?

          Gitlab.com? && !Gitlab.jh?
        end

        def temp_column_removed?(table_name, column_name)
          !column_exists?(table_name.to_s, convert_to_bigint_column(column_name))
        end

        def columns_swapped?(table_name, column_name)
          table_columns = columns(table_name.to_s)
          temp_column_name = convert_to_bigint_column(column_name)

          column = table_columns.find { |c| c.name == column_name.to_s }
          temp_column = table_columns.find { |c| c.name == temp_column_name }

          column.sql_type == 'bigint' && temp_column.sql_type == 'integer'
        end

        def add_bigint_column_indexes(table_name, int_column_name)
          table_name = table_name.to_s
          int_column_name = int_column_name.to_s
          bigint_column_name = convert_to_bigint_column(int_column_name)

          unless column_exists?(table_name, bigint_column_name)
            say "Bigint column '#{bigint_column_name}' does not exist on #{table_name}"
            return
          end

          if primary_key(table_name) == int_column_name
            return create_primary_key_index(table_name, int_column_name, bigint_column_name)
          end

          indexes(table_name).each do |i|
            next unless Array(i.columns).join(' ').match?(/\b#{int_column_name}\b/)

            create_bigint_index(table_name, i, int_column_name, bigint_column_name)
          end
        end

        def create_primary_key_index(table_name, int_column_name, bigint_column_name)
          pk_index = PkIndexDefinition.new(
            name: "#{table_name}_pkey",
            columns: [int_column_name],
            unique: true
          )

          create_bigint_index(table_name, pk_index, int_column_name, bigint_column_name)
        end

        def drop_bigint_columns_indexes(table_name, int_columns)
          columns = Array(int_columns)
          big_int_columns = columns.map { |c| convert_to_bigint_column(c) }

          connection.indexes(table_name)
            .select { |idx| (idx.columns & big_int_columns).any? }
            .each { |idx| remove_index table_name, name: idx.name }
        end

        # default 'index_name' method is not used because this method can be reused while swapping/dropping the indexes
        def bigint_index_name(int_column_index_name)
          # First 20 digits of the hash is chosen to make sure it fits the 63 chars limit
          digest = Digest::SHA256.hexdigest(int_column_index_name).first(20)
          "bigint_idx_#{digest}"
        end

        private

        def create_bigint_index(table_name, index_definition, int_column_name, bigint_column_name)
          index_attributes = index_definition.as_json
          index_options = INDEX_OPTIONS_MAP
                            .transform_values { |key| index_attributes[key.to_s] }
                            .select { |_, v| v.present? }

          bigint_index_options = create_bigint_options(
            index_options,
            index_definition.name,
            int_column_name,
            bigint_column_name
          )

          add_concurrent_index(
            table_name,
            bigint_index_columns(int_column_name, bigint_column_name, index_definition.columns),
            name: bigint_index_options.delete(:name),
            ** bigint_index_options
          )
        end

        def bigint_index_columns(int_column_name, bigint_column_name, int_index_columns)
          if int_index_columns.is_a?(String)
            int_index_columns.gsub(/\b#{int_column_name}\b/, bigint_column_name)
          else
            int_index_columns.map do |column|
              column == int_column_name.to_s ? bigint_column_name : column
            end
          end
        end

        def create_bigint_options(index_options, int_index_name, int_column_name, bigint_column_name)
          index_options[:name] = bigint_index_name(int_index_name)
          index_options[:where]&.gsub!(/\b#{int_column_name}\b/, bigint_column_name)

          # ordering on multiple columns will return a Hash instead of string
          index_options[:order] =
            if index_options[:order].is_a?(Hash)
              index_options[:order].to_h do |column, order|
                column = bigint_column_name if column == int_column_name
                [column, order]
              end
            else
              index_options[:order]&.gsub(/\b#{int_column_name}\b/, bigint_column_name)
            end

          index_options.select { |_, v| v.present? }
        end
      end
    end
  end
end
