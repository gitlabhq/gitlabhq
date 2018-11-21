# This patches ActiveRecord so indexes for binary columns created using the
# MySQL adapter apply a length of 20. Otherwise MySQL can't create an index on
# binary columns.

# This module can be removed once a Rails 5 schema is used.
# It can't be wrapped in a check that checks Gitlab.rails5? because
# the old Rails 4 schema layout is still used
module MysqlSetLengthForBinaryIndex
  def add_index(table_name, column_names, options = {})
    options[:length] ||= {}
    Array(column_names).each do |column_name|
      column = ActiveRecord::Base.connection.columns(table_name).find { |c| c.name == column_name }

      if column&.type == :binary
        options[:length][column_name] = 20
      end
    end

    super(table_name, column_names, options)
  end
end

if defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
  ActiveRecord::ConnectionAdapters::Mysql2Adapter.send(:prepend, MysqlSetLengthForBinaryIndex)
end

module MysqlSetLengthForBinaryIndexAndIgnorePostgresOptionsForSchema
  # This method is used in Rails 5 schema loading as t.index
  def index(column_names, options = {})
    # Ignore indexes that use opclasses,
    # also see config/initializers/mysql_ignore_postgresql_options.rb
    if options[:opclasses]
      warn "WARNING: index on columns #{column_names} uses unsupported option, skipping."
      return
    end

    # when running rails 4 with rails 5 schema, rails 4 doesn't support multiple
    # indexes on the same set of columns. Mysql doesn't support partial indexes, so if
    # an index already exists and we add another index, skip it if it's partial:
    # see https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/21492#note_102821326
    if !Gitlab.rails5? && indexes[column_names] && options[:where]
      warn "WARNING: index on columns #{column_names} already exists and partial index is not supported, skipping."
      return
    end

    options[:length] ||= {}
    Array(column_names).each do |column_name|
      column = columns.find { |c| c.name == column_name }

      if column&.type == :binary
        options[:length][column_name] = 20
      end
    end

    super(column_names, options)
  end
end

def mysql_adapter?
  defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter) && ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
end

if Gitlab.rails5?
  if defined?(ActiveRecord::ConnectionAdapters::MySQL::TableDefinition)
    ActiveRecord::ConnectionAdapters::MySQL::TableDefinition.send(:prepend, MysqlSetLengthForBinaryIndexAndIgnorePostgresOptionsForSchema)
  end
elsif mysql_adapter? && defined?(ActiveRecord::ConnectionAdapters::TableDefinition)
  ActiveRecord::ConnectionAdapters::TableDefinition.send(:prepend, MysqlSetLengthForBinaryIndexAndIgnorePostgresOptionsForSchema)
end
