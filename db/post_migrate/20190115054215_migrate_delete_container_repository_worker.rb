# frozen_string_literal: true

class MigrateDeleteContainerRepositoryWorker < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate('delete_container_repository', to: 'container_repository:delete_container_repository')
  end

  def down
    sidekiq_queue_migrate('container_repository:delete_container_repository', to: 'delete_container_repository')
  end
end
