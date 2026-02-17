# frozen_string_literal: true

module InitializerConnections
  # Raises if new database connections established within the block
  #
  # NOTE: this does not prevent existing connections that is already checked out
  # from being used. You will need other means to prevent that such as by
  # clearing all connections as implemented in the
  # `:clear_active_connections_again` initializer for routes
  #
  def self.raise_if_new_database_connection
    return yield if Gitlab::Utils.to_boolean(ENV['SKIP_RAISE_ON_INITIALIZE_CONNECTIONS'])

    previous_connection_counts =
      ActiveRecord::Base.connection_handler.connection_pool_list(ApplicationRecord.current_role).map do |pool|
        pool.connections.size
      end

    results = debug_database_queries do
      yield
    end

    new_connection_counts =
      ActiveRecord::Base.connection_handler.connection_pool_list(ApplicationRecord.current_role).map do |pool|
        pool.connections.size
      end

    raise_database_connection_made_error unless previous_connection_counts == new_connection_counts

    results
  end

  def self.debug_database_queries
    return yield if Gitlab::Utils.to_boolean(ENV['SKIP_DEBUG_INITIALIZE_CONNECTIONS'], default: Rails.env.production?)

    callback = ->(_name, _started, _finished, _unique_id, payload) do
      logger.debug("InitializerConnections Query: #{payload[:sql]}")

      Gitlab::BacktraceCleaner.clean_backtrace(caller).each do |line|
        logger.debug("InitializerConnections Backtrace: #{line}")
      end
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      yield
    end
  end

  def self.raise_database_connection_made_error
    message = "Database connection should not be called during initializers. Read more at https://docs.gitlab.com/ee/development/rails_initializers.html#database-connections-in-initializers"

    raise message
  end

  def self.logger
    @logger ||= ActiveRecord::Base.logger || Rails.logger
  end
end
