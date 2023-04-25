# frozen_string_literal: true
class UpdateApplicationSettingsContainerRegistryExpPolWorkerCapacityDefault < Gitlab::Database::Migration[1.0]
  class Settings < ActiveRecord::Base
    self.table_name = 'application_settings'
  end

  def up
    change_column_default(:application_settings, :container_registry_expiration_policies_worker_capacity, from: 0, to: 4)

    current_settings = Settings.first

    if current_settings&.container_registry_expiration_policies_worker_capacity == 0
      current_settings.update!(container_registry_expiration_policies_worker_capacity: 4)
    end
  end

  def down
    change_column_default(:application_settings, :container_registry_expiration_policies_worker_capacity, from: 4, to: 0)
  end
end
