# frozen_string_literal: true

# Don't handle sidekiq configuration as it
# has its own special active record configuration here
if defined?(ActiveRecord::Base) && !Sidekiq.server?
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    ActiveSupport.on_load(:active_record) do
      ActiveRecord::Base.establish_connection

      Rails.logger.debug("ActiveRecord connection established") # rubocop:disable Gitlab/RailsLogger
    end
  end
end

if defined?(ActiveRecord::Base)
  Gitlab::Cluster::LifecycleEvents.on_before_fork do
    # the following is highly recommended for Rails + "preload_app true"
    # as there's no need for the master process to hold a connection
    ActiveRecord::Base.connection.disconnect!

    Rails.logger.debug("ActiveRecord connection disconnected") # rubocop:disable Gitlab/RailsLogger
  end
end
