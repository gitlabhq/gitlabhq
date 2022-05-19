# frozen_string_literal: true

# Don't handle sidekiq configuration as it
# has its own special active record configuration here
if defined?(ActiveRecord::Base) && !Gitlab::Runtime.sidekiq?
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    ActiveSupport.on_load(:active_record) do
      # rubocop:disable Database/MultipleDatabases
      ActiveRecord::Base.establish_connection # rubocop:disable Database/EstablishConnection
      # rubocop:enable Database/MultipleDatabases

      Gitlab::AppLogger.debug("ActiveRecord connection established")
    end
  end
end

if defined?(ActiveRecord::Base)
  Gitlab::Cluster::LifecycleEvents.on_before_fork do
    raise 'ActiveRecord connection not established. Unable to start.' unless ApplicationRecord.database.exists?

    # the following is highly recommended for Rails + "preload_app true"
    # as there's no need for the master process to hold a connection
    ActiveRecord::Base.clear_all_connections! # rubocop:disable Database/MultipleDatabases

    Gitlab::AppLogger.debug("ActiveRecord connections disconnected")
  end
end
