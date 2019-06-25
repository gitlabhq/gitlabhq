# This patches ActiveRecord so indexes created using the MySQL adapter ignore
# any PostgreSQL specific options (e.g. `using: :gin`).
#
# These patches do the following for MySQL:
#
# 1. Indexes created using the :opclasses option are ignored (as they serve no
#    purpose on MySQL).
# 2. When creating an index with `using: :gin` the `using` option is discarded
#    as :gin is not a valid value for MySQL.
# 3. The `:opclasses` option is stripped from add_index_options in case it's
#    used anywhere other than in the add_index methods.

if defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
  module ActiveRecord
    module ConnectionAdapters
      class Mysql2Adapter < AbstractMysqlAdapter
        alias_method :__gitlab_add_index, :add_index
        alias_method :__gitlab_add_index_options, :add_index_options

        def add_index(table_name, column_name, options = {})
          unless options[:opclasses]
            __gitlab_add_index(table_name, column_name, options)
          end
        end

        def add_index_options(table_name, column_name, options = {})
          if options[:using] && options[:using] == :gin
            options = options.dup
            options.delete(:using)
          end

          if options[:opclasses]
            options = options.dup
            options.delete(:opclasses)
          end

          __gitlab_add_index_options(table_name, column_name, options)
        end
      end
    end
  end
end
