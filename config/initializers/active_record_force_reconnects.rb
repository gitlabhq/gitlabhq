# frozen_string_literal: true

Gitlab::Database::ConnectionTimer.configure do |config|
  config.interval = Rails.application.config_for(:database)[:force_reconnect_interval]
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(Gitlab::Database::PostgresqlAdapter::ForceDisconnectableMixin)
