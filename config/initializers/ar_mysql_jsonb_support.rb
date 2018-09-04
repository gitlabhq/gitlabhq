# frozen_string_literal: true

require 'active_record/connection_adapters/abstract_mysql_adapter'
require 'active_record/connection_adapters/abstract/schema_definitions'

if Gitlab::Database.mysql?
  module ActiveRecord
    module ConnectionAdapters
      class AbstractMysqlAdapter
        NATIVE_DATABASE_TYPES.merge!(
          jsonb: { name: "text", limit: 262144 }
        )
      end
    end
  end

  module ActiveRecord
    module ConnectionAdapters
      class TableDefinition
        def jsonb(*args, **options)
          args.each { |name| column(name, :jsonb, options) }
        end
      end
    end
  end
end
