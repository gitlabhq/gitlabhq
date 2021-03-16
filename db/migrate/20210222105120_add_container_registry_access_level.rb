# frozen_string_literal: true

class AddContainerRegistryAccessLevel < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column(
        :project_features,
        :container_registry_access_level,
        :integer,
        default: 0, # ProjectFeature::DISABLED value
        null: false
      )
    end
  end

  def down
    with_lock_retries do
      remove_column :project_features, :container_registry_access_level
    end
  end
end
