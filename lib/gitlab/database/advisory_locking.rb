# An advisory lock is an application-level database lock which isn't tied
# to a specific table or row.
#
# Postgres names its advisory locks with integers, while MySQL uses strings.
# We support both here by using a `LOCK_TYPES` map of symbols to integers.
# The symbol (stringified) is used for MySQL, and the corresponding integer
# is used for Postgres.
module Gitlab
  module Database
    class AdvisoryLocking
      LOCK_TYPES = {
        ghost_user: 1
      }

      def initialize(lock_type)
        @lock_type = lock_type
      end

      def lock
        ensure_valid_lock_type!

        query =
          if Gitlab::Database.postgresql?
            Arel::SelectManager.new(ActiveRecord::Base).project(
              Arel::Nodes::NamedFunction.new("pg_advisory_lock", [LOCK_TYPES[@lock_type]])
            )
          elsif Gitlab::Database.mysql?
            Arel::SelectManager.new(ActiveRecord::Base).project(
              Arel::Nodes::NamedFunction.new("get_lock", [Arel.sql("'#{@lock_type}'"), -1])
            )
          end

        run_query(query)
      end

      def unlock
        ensure_valid_lock_type!

        query =
          if Gitlab::Database.postgresql?
            Arel::SelectManager.new(ActiveRecord::Base).project(
              Arel::Nodes::NamedFunction.new("pg_advisory_unlock", [LOCK_TYPES[@lock_type]])
            )
          elsif Gitlab::Database.mysql?
            Arel::SelectManager.new(ActiveRecord::Base).project(
              Arel::Nodes::NamedFunction.new("release_lock", [Arel.sql("'#{@lock_type}'")])
            )
          end

        run_query(query)
      end

      private

      def ensure_valid_lock_type!
        unless valid_lock_type?
          raise RuntimeError, "Trying to use an advisory lock with an invalid lock type, #{@lock_type}."
        end
      end

      def valid_lock_type?
        LOCK_TYPES.keys.include?(@lock_type)
      end

      def run_query(arel_query)
        ActiveRecord::Base.connection.execute(arel_query.to_sql)
      end
    end
  end
end
