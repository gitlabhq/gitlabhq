# frozen_string_literal: true

return unless Gitlab::Runtime.application?

ActiveSupport.on_load(:gitlab_db_load_balancer, run_once: true) do
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    Gitlab::Database.database_base_models.each_key do |database_name|
      capture_task = Gitlab::Database::Capture::Task.new(database_name: database_name)
      Gitlab::BackgroundTask.new(capture_task).start
    end
  end
end
