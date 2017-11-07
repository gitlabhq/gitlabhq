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
        priv =
          if Database.postgresql?
            where(privilege_type: 'TRIGGER', table_name: table)
              .where('grantee = user')
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

            Grant.from("(#{union}) privs")
          end

        priv.any?
      end
    end
  end
end
