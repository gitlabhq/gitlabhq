# frozen_string_literal: true

class AddContainerExpirationPolicyWorkerSettingsToApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    unless column_exists?(:application_settings, :container_registry_expiration_policies_worker_capacity)
      add_column(:application_settings, :container_registry_expiration_policies_worker_capacity, :integer, default: 0, null: false)
    end
  end

  def down
    if column_exists?(:application_settings, :container_registry_expiration_policies_worker_capacity)
      remove_column(:application_settings, :container_registry_expiration_policies_worker_capacity)
    end
  end
end
