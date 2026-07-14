# frozen_string_literal: true

class AddPolicyStoreExperimentEnabledToNamespaceSettings < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :namespace_settings, :policy_store_experiment_enabled, :boolean, default: false, null: false
  end
end
