# frozen_string_literal: true

# Don't handle sidekiq configuration as it
# has its own special active record configuration here
if defined?(ActiveRecord::Base) && !Gitlab::Runtime.sidekiq?
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    ActiveSupport.on_load(:active_record) do
      ActiveRecord::Base.establish_connection

      Gitlab::AppLogger.debug("ActiveRecord connection established")
    end
  end
end

if defined?(ActiveRecord::Base)
  Gitlab::Cluster::LifecycleEvents.on_before_fork do
    raise 'ActiveRecord connection not established. Unable to start.' unless Gitlab::Database.main.exists?

    # the following is highly recommended for Rails + "preload_app true"
    # as there's no need for the master process to hold a connection
    ActiveRecord::Base.connection.disconnect!

    Gitlab::AppLogger.debug("ActiveRecord connection disconnected")
  end
end
