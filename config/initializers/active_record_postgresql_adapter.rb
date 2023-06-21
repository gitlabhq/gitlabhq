# frozen_string_literal: true

if Gitlab::Utils.to_boolean(ENV['ENABLE_ACTIVERECORD_TYPEMAP_CACHE'], default: true)
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(Gitlab::Database::PostgresqlAdapter::TypeMapCache)
end
