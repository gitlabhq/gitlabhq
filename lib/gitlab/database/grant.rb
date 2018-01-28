module Gitlab
  module Database
    # Model that can be used for querying permissions of a SQL user.
    class Grant < ActiveRecord::Base
      self.table_name =
        if Database.postgresql?
          'information_schema.role_table_grants'
        else
          'information_schema.schema_privileges'
        end

      # Returns true if the current user can create and execute triggers on the
      # given table.
      def self.create_and_execute_trigger?(table)
        if Database.postgresql?
          # We _must not_ use quote_table_name as this will produce double
          # quotes on PostgreSQL and for "has_table_privilege" we need single
          # quotes.
          quoted_table = connection.quote(table)

          begin
            from(nil)
              .pluck("has_table_privilege(#{quoted_table}, 'TRIGGER')")
              .first
          rescue ActiveRecord::StatementInvalid
            # This error is raised when using a non-existing table name. In this
            # case we just want to return false as a user technically can't
            # create triggers for such a table.
            false
          end
        else
          queries = [
            Grant.select(1)
              .from('information_schema.user_privileges')
              .where("PRIVILEGE_TYPE = 'SUPER'")
              .where("GRANTEE = CONCAT('\\'', REPLACE(CURRENT_USER(), '@', '\\'@\\''), '\\'')"),

            Grant.select(1)
              .from('information_schema.schema_privileges')
              .where("PRIVILEGE_TYPE = 'TRIGGER'")
              .where('TABLE_SCHEMA = ?', Gitlab::Database.database_name)
              .where("GRANTEE = CONCAT('\\'', REPLACE(CURRENT_USER(), '@', '\\'@\\''), '\\'')")
          ]

          union = SQL::Union.new(queries).to_sql

          Grant.from("(#{union}) privs").any?
        end
      end
    end
  end
end
