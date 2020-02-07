# frozen_string_literal: true

class MigratePropagateServiceTemplateSidekiqQueue < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'propagate_service_template', to: 'propagate_instance_level_service'
  end

  def down
    sidekiq_queue_migrate 'propagate_instance_level_service', to: 'propagate_service_template'
  end
end
