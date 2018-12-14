# This patches ActiveRecord so indexes for binary columns created using the
# MySQL adapter apply a length of 20. Otherwise MySQL can't create an index on
# binary columns.

module MysqlSetLengthForBinaryIndexAndIgnorePostgresOptionsForSchema
  # This method is used in Rails 5 schema loading as t.index
  def index(column_names, options = {})
    # Ignore indexes that use opclasses,
    # also see config/initializers/mysql_ignore_postgresql_options.rb
    if options[:opclasses]
      warn "WARNING: index on columns #{column_names} uses unsupported option, skipping."
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

if defined?(ActiveRecord::ConnectionAdapters::MySQL::TableDefinition)
  ActiveRecord::ConnectionAdapters::MySQL::TableDefinition.send(:prepend, MysqlSetLengthForBinaryIndexAndIgnorePostgresOptionsForSchema)
end
