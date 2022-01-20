# frozen_string_literal: true

module Gitlab
  module Database
    # Model that can be used for querying permissions of a SQL user.
    class Grant
      # Returns true if the current user can create and execute triggers on the
      # given table.
      def self.create_and_execute_trigger?(table)
        # We _must not_ use quote_table_name as this will produce double
        # quotes on PostgreSQL and for "has_table_privilege" we need single
        # quotes.
        connection = ApplicationRecord.connection
        quoted_table = connection.quote(table)

        begin
          connection.select_one("SELECT has_table_privilege(#{quoted_table}, 'TRIGGER')").present?
        rescue ActiveRecord::StatementInvalid
          # This error is raised when using a non-existing table name. In this
          # case we just want to return false as a user technically can't
          # create triggers for such a table.
          false
        end
      end
    end
  end
end
