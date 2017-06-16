# ActiveRecord custom data type for storing datetimes with timezone information.
# See https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/11229

if Gitlab::Database.postgresql?
  require 'active_record/connection_adapters/postgresql_adapter'

  module ActiveRecord
    module ConnectionAdapters
      class PostgreSQLAdapter
        NATIVE_DATABASE_TYPES.merge!(datetime_with_timezone: { name: 'timestamptz' })
      end
    end
  end
elsif Gitlab::Database.mysql?
  require 'active_record/connection_adapters/mysql2_adapter'

  module ActiveRecord
    module ConnectionAdapters
      class AbstractMysqlAdapter
        NATIVE_DATABASE_TYPES.merge!(datetime_with_timezone: { name: 'timestamp' })
      end
    end
  end
end
