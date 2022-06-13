# frozen_string_literal: true

class MigrateIrkerWorkerQueue < Gitlab::Database::Migration[2.0]
  def up
    sidekiq_queue_migrate 'irker', to: 'integrations_irker'
  end

  def down
    sidekiq_queue_migrate 'integrations_irker', to: 'irker'
  end
end
