# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module ConvertToBigint
        # This helper is extracted for the purpose of
        # https://gitlab.com/gitlab-org/gitlab/-/issues/392815
        # so that we can test all combinations just once,
        # and simplify migration tests.
        #
        # Once we are done with the PK conversions we can remove this.
        def com_or_dev_or_test_but_not_jh?
          return true if Gitlab.dev_or_test_env?

          Gitlab.com? && !Gitlab.jh?
        end

        def temp_column_removed?(table_name, column_name)
          !column_exists?(table_name.to_s, convert_to_bigint_column(column_name))
        end

        def columns_swapped?(table_name, column_name)
          table_columns = columns(table_name.to_s)
          temp_column_name = convert_to_bigint_column(column_name)

          column = table_columns.find { |c| c.name == column_name.to_s }
          temp_column = table_columns.find { |c| c.name == temp_column_name }

          column.sql_type == 'bigint' && temp_column.sql_type == 'integer'
        end
      end
    end
  end
end
