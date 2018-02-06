if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    module LimitFilter
      def add_column(table_name, column_name, type, options = {})
        options.delete(:limit) if type == :text
        super(table_name, column_name, type, options)
      end

      def change_column(table_name, column_name, type, options = {})
        options.delete(:limit) if type == :text
        super(table_name, column_name, type, options)
      end
    end

    prepend ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::LimitFilter

    class TableDefinition
      def text(*args)
        options = args.extract_options!
        options.delete(:limit)
        column_names = args
        type = :text
        column_names.each { |name| column(name, type, options) }
      end
    end
  end
end
