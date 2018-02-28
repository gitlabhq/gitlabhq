module Gitlab
  module Database
    # Model that can be used for querying permissions of a SQL user.
    class Grant < ActiveRecord::Base
      self.table_name =
        if Database.postgresql?
          'information_schema.role_table_grants'
        else
          'mysql.user'
        end

      def self.scope_to_current_user
        if Database.postgresql?
          where('grantee = user')
        else
          where("CONCAT(User, '@', Host) = current_user()")
        end
      end

      # Returns true if the current user can create and execute triggers on the
      # given table.
      def self.create_and_execute_trigger?(table)
        priv =
          if Database.postgresql?
            where(privilege_type: 'TRIGGER', table_name: table)
          else
            where(Trigger_priv: 'Y')
          end

        priv.scope_to_current_user.any?
      end
    end
  end
end
