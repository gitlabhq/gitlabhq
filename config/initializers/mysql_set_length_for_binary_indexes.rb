# This patches ActiveRecord so indexes for binary columns created using the
# MySQL adapter apply a length of 20. Otherwise MySQL can't create an index on
# binary columns.

# This module can be removed once a Rails 5 schema is used.
# It can't be wrapped in a check that checks Gitlab.rails5? because
# the old Rails 4 schema layout is still used
module MysqlSetLengthForBinaryIndex
  def add_index(table_name, column_names, options = {})
    Array(column_names).each do |column_name|
      column = ActiveRecord::Base.connection.columns(table_name).find { |c| c.name == column_name }

      if column&.type == :binary
        options[:length] = 20
      end
    end

    super(table_name, column_names, options)
  end
end

if defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
  ActiveRecord::ConnectionAdapters::Mysql2Adapter.send(:prepend, MysqlSetLengthForBinaryIndex)
end

if Gitlab.rails5?
  module MysqlSetLengthForBinaryIndexAndIgnorePostgresOptionsForSchema
    # This method is used in Rails 5 schema loading as t.index
    def index(column_names, options = {})
      Array(column_names).each do |column_name|
        column = columns.find { |c| c.name == column_name }

        if column&.type == :binary
          options[:length] = 20
        end
      end

      # Ignore indexes that use opclasses,
      # also see config/initializers/mysql_ignore_postgresql_options.rb
      unless options[:opclasses]
        super(column_names, options)
      end
    end
  end

  if defined?(ActiveRecord::ConnectionAdapters::MySQL::TableDefinition)
    ActiveRecord::ConnectionAdapters::MySQL::TableDefinition.send(:prepend, MysqlSetLengthForBinaryIndexAndIgnorePostgresOptionsForSchema)
  end
end
