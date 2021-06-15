# frozen_string_literal: true

if Gitlab::Utils.to_boolean(ENV['ENABLE_ACTIVERECORD_EMPTY_PING'], default: true)
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(Gitlab::Database::PostgresqlAdapter::EmptyQueryPing)
end

if Gitlab::Utils.to_boolean(ENV['ENABLE_ACTIVERECORD_TYPEMAP_CACHE'], default: true)
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(Gitlab::Database::PostgresqlAdapter::TypeMapCache)
end
