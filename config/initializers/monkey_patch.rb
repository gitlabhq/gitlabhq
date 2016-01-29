## This patch is from rails 4.2-stable. Remove it when 4.2.6 is released
## https://github.com/rails/rails/issues/21108

module ActiveRecord
  module ConnectionAdapters
    class AbstractMysqlAdapter < AbstractAdapter
      # SHOW VARIABLES LIKE 'name'
      def show_variable(name)
        variables = select_all("select @@#{name} as 'Value'", 'SCHEMA')
        variables.first['Value'] unless variables.empty?
      rescue ActiveRecord::StatementInvalid
        nil
      end

      
      # MySQL is too stupid to create a temporary table for use subquery, so we have
      # to give it some prompting in the form of a subsubquery. Ugh!
      def subquery_for(key, select)
        subsubselect = select.clone
        subsubselect.projections = [key]

        subselect = Arel::SelectManager.new(select.engine)
        subselect.project Arel.sql(key.name)
        # Materialized subquery by adding distinct
        # to work with MySQL 5.7.6 which sets optimizer_switch='derived_merge=on'
        subselect.from subsubselect.distinct.as('__active_record_temp')
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class MysqlAdapter < AbstractMysqlAdapter
      ADAPTER_NAME = 'MySQL'.freeze

      # Get the client encoding for this database
      def client_encoding
        return @client_encoding if @client_encoding

        result = exec_query(
          "select @@character_set_client",
          'SCHEMA')
        @client_encoding = ENCODINGS[result.rows.last.last]
      end
    end
  end
end
