# frozen_string_literal: true

class AddModelRegistryAccessLevelToProjectFeature < Gitlab::Database::Migration[2.2]
  OPERATIONS_DEFAULT_VALUE = 20

  enable_lock_retries!
  milestone '16.7'

  def change
    add_column :project_features,
      :model_registry_access_level,
      :integer,
      null: false,
      default: OPERATIONS_DEFAULT_VALUE
  end
end
