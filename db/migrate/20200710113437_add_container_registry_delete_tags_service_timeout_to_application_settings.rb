# frozen_string_literal: true

class AddContainerRegistryDeleteTagsServiceTimeoutToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column(
      :application_settings,
      :container_registry_delete_tags_service_timeout,
      :integer,
      default: 250,
      null: false
    )
  end

  def down
    remove_column(:application_settings, :container_registry_delete_tags_service_timeout)
  end
end
