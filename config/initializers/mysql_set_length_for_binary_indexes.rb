# This patches ActiveRecord so indexes for binary columns created using the
# MySQL adapter apply a length of 20. Otherwise MySQL can't create an index on
# binary columns.

if defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
  module ActiveRecord
    module ConnectionAdapters
      class Mysql2Adapter < AbstractMysqlAdapter
        alias_method :__gitlab_add_index2, :add_index

        def add_index(table_name, column_names, options = {})
          Array(column_names).each do |column_name|
            column = ActiveRecord::Base.connection.columns(table_name).find { |c| c.name == column_name }

            if column&.type == :binary
              options[:length] = 20
            end
          end

          __gitlab_add_index2(table_name, column_names, options)
        end
      end
    end
  end
end
