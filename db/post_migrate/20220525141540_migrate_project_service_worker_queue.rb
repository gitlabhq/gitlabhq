# frozen_string_literal: true

class MigrateProjectServiceWorkerQueue < Gitlab::Database::Migration[2.0]
  def up
    sidekiq_queue_migrate 'project_service', to: 'integrations_execute'
  end

  def down
    sidekiq_queue_migrate 'integrations_execute', to: 'project_service'
  end
end
