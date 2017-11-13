# rubocop:disable all

# These changes add support for PostgreSQL operator classes when creating
# indexes and dumping/loading schemas. Taken from Rails pull request
# https://github.com/rails/rails/pull/19090.
#
# License:
#
# Copyright (c) 2004-2016 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'date'
require 'set'
require 'bigdecimal'
require 'bigdecimal/util'

# As the Struct definition is changed in this PR/patch we have to first remove
# the existing one.
ActiveRecord::ConnectionAdapters.send(:remove_const, :IndexDefinition)

module ActiveRecord
  module ConnectionAdapters #:nodoc:
    # Abstract representation of an index definition on a table. Instances of
    # this type are typically created and returned by methods in database
    # adapters. e.g. ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter#indexes
    class IndexDefinition < Struct.new(:table, :name, :unique, :columns, :lengths, :orders, :where, :type, :using, :opclasses) #:nodoc:
    end
  end
end


module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module SchemaStatements
      def add_index_options(table_name, column_name, options = {}) #:nodoc:
        column_names = Array(column_name)
        index_name   = index_name(table_name, column: column_names)

        options.assert_valid_keys(:unique, :order, :name, :where, :length, :internal, :using, :algorithm, :type, :opclasses)

        index_type = options[:unique] ? "UNIQUE" : ""
        index_type = options[:type].to_s if options.key?(:type)
        index_name = options[:name].to_s if options.key?(:name)
        max_index_length = options.fetch(:internal, false) ? index_name_length : allowed_index_name_length

        if options.key?(:algorithm)
          algorithm = index_algorithms.fetch(options[:algorithm]) {
            raise ArgumentError.new("Algorithm must be one of the following: #{index_algorithms.keys.map(&:inspect).join(', ')}")
          }
        end

        using = "USING #{options[:using]}" if options[:using].present?

        if supports_partial_index?
          index_options = options[:where] ? " WHERE #{options[:where]}" : ""
        end

        if index_name.length > max_index_length
          raise ArgumentError, "Index name '#{index_name}' on table '#{table_name}' is too long; the limit is #{max_index_length} characters"
        end
        if table_exists?(table_name) && index_name_exists?(table_name, index_name, false)
          raise ArgumentError, "Index name '#{index_name}' on table '#{table_name}' already exists"
        end
        index_columns = quoted_columns_for_index(column_names, options).join(", ")

        [index_name, index_type, index_columns, index_options, algorithm, using]
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module SchemaStatements
        # Returns an array of indexes for the given table.
        def indexes(table_name, name = nil)
           result = query(<<-SQL, 'SCHEMA')
             SELECT distinct i.relname, d.indisunique, d.indkey, pg_get_indexdef(d.indexrelid), t.oid
             FROM pg_class t
             INNER JOIN pg_index d ON t.oid = d.indrelid
             INNER JOIN pg_class i ON d.indexrelid = i.oid
             WHERE i.relkind = 'i'
               AND d.indisprimary = 'f'
               AND t.relname = '#{table_name}'
               AND i.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname = ANY (current_schemas(false)) )
            ORDER BY i.relname
          SQL

          result.map do |row|
            index_name = row[0]
            unique = row[1] == 't'
            indkey = row[2].split(" ")
            inddef = row[3]
            oid = row[4]

            columns = Hash[query(<<-SQL, "SCHEMA")]
            SELECT a.attnum, a.attname
            FROM pg_attribute a
            WHERE a.attrelid = #{oid}
            AND a.attnum IN (#{indkey.join(",")})
            SQL

            column_names = columns.values_at(*indkey).compact

            unless column_names.empty?
              # add info on sort order for columns (only desc order is explicitly specified, asc is the default)
              desc_order_columns = inddef.scan(/(\w+) DESC/).flatten
              orders = desc_order_columns.any? ? Hash[desc_order_columns.map {|order_column| [order_column, :desc]}] : {}
              where = inddef.scan(/WHERE (.+)$/).flatten[0]
              using = inddef.scan(/USING (.+?) /).flatten[0].to_sym
              opclasses = Hash[inddef.scan(/\((.+?)\)(?:$| WHERE )/).flatten[0].split(',').map do |column_and_opclass|
                                 column, opclass = column_and_opclass.split(' ').map(&:strip)
                                 [column, opclass] if opclass
                               end.compact]

              IndexDefinition.new(table_name, index_name, unique, column_names, [], orders, where, nil, using, opclasses)
            end
          end.compact
        end

        def add_index(table_name, column_name, options = {}) #:nodoc:
          index_name, index_type, index_columns_and_opclasses, index_options, index_algorithm, index_using = add_index_options(table_name, column_name, options)
          execute "CREATE #{index_type} INDEX #{index_algorithm} #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} #{index_using} (#{index_columns_and_opclasses})#{index_options}"
        end

        protected

          def quoted_columns_for_index(column_names, options = {})
            column_opclasses = options[:opclasses] || {}
            column_names.map {|name| "#{quote_column_name(name)} #{column_opclasses[name]}"}
          end
      end
    end
  end
end

module ActiveRecord
  class SchemaDumper
    private

      def indexes(table, stream)
        if (indexes = @connection.indexes(table)).any?
          add_index_statements = indexes.map do |index|
            statement_parts = [
              "add_index #{remove_prefix_and_suffix(index.table).inspect}",
              index.columns.inspect,
              "name: #{index.name.inspect}",
            ]
            statement_parts << 'unique: true' if index.unique

            index_lengths = (index.lengths || []).compact
            statement_parts << "length: #{Hash[index.columns.zip(index.lengths)].inspect}" if index_lengths.any?

            index_orders = index.orders || {}
            statement_parts << "order: #{index.orders.inspect}" if index_orders.any?
            statement_parts << "where: #{index.where.inspect}" if index.where
            statement_parts << "using: #{index.using.inspect}" if index.using
            statement_parts << "type: #{index.type.inspect}" if index.type
            statement_parts << "opclasses: #{index.opclasses}" if index.opclasses.present?

            "  #{statement_parts.join(', ')}"
          end

          stream.puts add_index_statements.sort.join("\n")
          stream.puts
        end
      end
  end
end
