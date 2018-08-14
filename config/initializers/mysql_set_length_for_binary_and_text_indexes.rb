# This patches ActiveRecord so indexes for binary and text columns created
# using the MySQL adapter apply a length of 20. Otherwise MySQL can't create an
# index on binary and text columns.

module MysqlSetLengthForBinaryAndTextIndex
  def add_index(table_name, column_names, options = {})
    Array(column_names).each do |column_name|
      column = ActiveRecord::Base.connection.columns(table_name).find { |c| c.name == column_name }

      if column&.type == :binary || column&.type == :text
        options[:length] = 20
      end
    end

    super(table_name, column_names, options)
  end
end

if defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
  ActiveRecord::ConnectionAdapters::Mysql2Adapter.send(:prepend, MysqlSetLengthForBinaryAndTextIndex)
end
