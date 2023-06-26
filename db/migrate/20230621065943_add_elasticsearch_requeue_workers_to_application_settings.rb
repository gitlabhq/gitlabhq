# frozen_string_literal: true

class AddElasticsearchRequeueWorkersToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :elasticsearch_requeue_workers, :boolean, null: false, default: false
  end
end
