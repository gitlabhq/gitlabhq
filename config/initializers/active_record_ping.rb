# # frozen_string_literal: true

if Gitlab::Utils.to_boolean(ENV['ENABLE_ACTIVERECORD_EMPTY_PING'], default: false)
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(Gitlab::Database::PostgresqlAdapter::EmptyQueryPing)
end
