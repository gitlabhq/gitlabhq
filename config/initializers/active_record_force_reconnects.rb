# frozen_string_literal: true

Gitlab::Database::ConnectionTimer.configure do |config|
  configuration_hash = ActiveRecord::Base.configurations.find_db_config(Rails.env).configuration_hash
  config.interval = configuration_hash[:force_reconnect_interval]
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(Gitlab::Database::PostgresqlAdapter::ForceDisconnectableMixin)
