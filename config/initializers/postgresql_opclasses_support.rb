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
    class IndexDefinition < Struct.new(:table, :name, :unique, :columns, :lengths, :orders, :where, :type, :using, :opclasses, :comment) #:nodoc
    end
  end
end


module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module SchemaStatements
      def add_index_options(table_name, column_name, comment: nil, **options) #:nodoc:
        column_names = index_column_names(column_name)

        options.assert_valid_keys(:unique, :order, :name, :where, :length, :internal, :using, :algorithm, :type, :opclasses)

        index_type = options[:type].to_s if options.key?(:type)
        index_type ||= options[:unique] ? "UNIQUE" : ""
        index_name = options[:name].to_s if options.key?(:name)
        index_name ||= index_name(table_name, column_names)
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
        if data_source_exists?(table_name) && index_name_exists?(table_name, index_name, false)
          raise ArgumentError, "Index name '#{index_name}' on table '#{table_name}' already exists"
        end
        index_columns = quoted_columns_for_index(column_names, options).join(", ")

        [index_name, index_type, index_columns, index_options, algorithm, using, comment]
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters # :nodoc:
    class PostgreSQLAdapter
      private

      def add_index_opclass(column_names, options = {})
        opclass = if options[:opclasses].is_a?(Hash)
                    options[:opclasses].symbolize_keys
                  else
                    Hash.new { |hash, column| hash[column] = options[:opclasses].to_s }
                  end
        column_names.each do |name, column|
          column << " #{opclass[name]}" if opclass[name].present?
        end
      end

      def add_options_for_index_columns(quoted_columns, **options)
        quoted_columns = add_index_opclass(quoted_columns, options)
        super
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
          table = Utils.extract_schema_qualified_name(table_name.to_s)

          result = query(<<-SQL, 'SCHEMA')
            SELECT distinct i.relname, d.indisunique, d.indkey, pg_get_indexdef(d.indexrelid), t.oid,
                            pg_catalog.obj_description(i.oid, 'pg_class') AS comment
            FROM pg_class t
            INNER JOIN pg_index d ON t.oid = d.indrelid
            INNER JOIN pg_class i ON d.indexrelid = i.oid
            LEFT JOIN pg_namespace n ON n.oid = i.relnamespace
            WHERE i.relkind = 'i'
              AND d.indisprimary = 'f'
              AND t.relname = '#{table.identifier}'
              AND n.nspname = #{table.schema ? "'#{table.schema}'" : 'ANY (current_schemas(false))'}
            ORDER BY i.relname
          SQL

          result.map do |row|
            index_name = row[0]
            unique = row[1]
            indkey = row[2].split(" ").map(&:to_i)
            inddef = row[3]
            oid = row[4]
            comment = row[5]

            using, expressions, where = inddef.scan(/ USING (\w+?) \((.+?)\)(?: WHERE (.+))?\z/).flatten

            if indkey.include?(0)
              columns = expressions
            else
              columns = Hash[query(<<-SQL.strip_heredoc, "SCHEMA")].values_at(*indkey).compact
                SELECT a.attnum, a.attname
                FROM pg_attribute a
                WHERE a.attrelid = #{oid}
                AND a.attnum IN (#{indkey.join(",")})
              SQL

              orders = {}
              opclasses = {}

              # add info on sort order (only desc order is explicitly specified, asc is the default)
              # and non-default opclasses
              expressions.scan(/(\w+)(?: (?!DESC)(\w+))?(?: (DESC))?/).each do |column, opclass, desc|
                opclasses[column] = opclass if opclass
                orders[column] = :desc if desc
              end

              # Use a string for the opclass description (instead of a hash) when all columns
              # have the same opclass specified.
              if columns.count == opclasses.count && opclasses.values.uniq.count == 1
                opclasses = opclasses.values.first
              end
            end

            IndexDefinition.new(table_name, index_name, unique, columns, [], orders, where, nil, using.to_sym, opclasses, comment.presence)
          end.compact
        end

        def add_index(table_name, column_name, options = {}) #:nodoc:
          index_name, index_type, index_columns_and_opclasses, index_options, index_algorithm, index_using, comment = add_index_options(table_name, column_name, options)
          execute("CREATE #{index_type} INDEX #{index_algorithm} #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} #{index_using} (#{index_columns_and_opclasses})#{index_options}").tap do
            execute "COMMENT ON INDEX #{quote_column_name(index_name)} IS #{quote(comment)}" if comment
          end
        end
      end
    end
  end
end

module ActiveRecord
  class SchemaDumper
    private

      def index_parts(index)
        index_parts = [
          index.columns.inspect,
          "name: #{index.name.inspect}",
        ]
        index_parts << 'unique: true' if index.unique

        index_lengths = (index.lengths || []).compact
        index_parts << "length: #{Hash[index.columns.zip(index.lengths)].inspect}" if index_lengths.any?

        index_orders = index.orders || {}
        index_parts << "order: #{index.orders.inspect}" if index_orders.any?
        index_parts << "where: #{index.where.inspect}" if index.where
        index_parts << "using: #{index.using.inspect}" if index.using
        index_parts << "type: #{index.type.inspect}" if index.type
        index_parts << "opclasses: #{index.opclasses.inspect}" if index.opclasses.present?
        index_parts << "comment: #{index.comment.inspect}" if index.comment
        index_parts
      end
  end
end
