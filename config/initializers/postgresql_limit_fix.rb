if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    class TableDefinition
      def text(*args)
        options = args.extract_options!
        options.delete(:limit)
        column_names = args
        type = :text
        column_names.each { |name| column(name, type, options) }
      end
    end

    def add_column_with_limit_filter(table_name, column_name, type, options = {})
      options.delete(:limit) if type == :text
      add_column_without_limit_filter(table_name, column_name, type, options)
    end

    def change_column_with_limit_filter(table_name, column_name, type, options = {})
      options.delete(:limit) if type == :text
      change_column_without_limit_filter(table_name, column_name, type, options)
    end

    alias_method_chain :add_column, :limit_filter
    alias_method_chain :change_column, :limit_filter
  end
end
