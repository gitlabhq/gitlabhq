require 'active_record/connection_adapters/abstract_mysql_adapter'

module ActiveRecord
  module ConnectionAdapters
    class AbstractMysqlAdapter
      NATIVE_DATABASE_TYPES.merge!(
        bigserial: { name: 'bigint(20) auto_increment PRIMARY KEY' }
      )
    end
  end
end
