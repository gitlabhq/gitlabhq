# frozen_string_literal: true

class RemovePropagateServiceTemplateWorker < Gitlab::Database::Migration[1.0]
  def up
    Sidekiq::Queue.new('propagate_service_template').clear
  end

  def down
    # no-op
  end
end
