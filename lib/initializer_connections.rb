# frozen_string_literal: true

module InitializerConnections
  # Prevents any database connections within the block
  # by using an empty connection handler
  # rubocop:disable Database/MultipleDatabases
  def self.with_disabled_database_connections
    return yield if Gitlab::Utils.to_boolean(ENV['SKIP_RAISE_ON_INITIALIZE_CONNECTIONS'])

    original_handler = ActiveRecord::Base.connection_handler

    dummy_handler = ActiveRecord::ConnectionAdapters::ConnectionHandler.new
    ActiveRecord::Base.connection_handler = dummy_handler

    yield

    if dummy_handler&.connection_pool_names&.present?
      raise "Unxpected connection_pools (#{dummy_handler.connection_pool_names}) ! Call `connects_to` before this block"
    end
  rescue ActiveRecord::ConnectionNotEstablished
    message = "Database connection should not be called during initializers. Read more at https://docs.gitlab.com/ee/development/rails_initializers.html#database-connections-in-initializers"

    raise message
  ensure
    ActiveRecord::Base.connection_handler = original_handler
    dummy_handler&.clear_all_connections!
  end
  # rubocop:enable Database/MultipleDatabases
end
