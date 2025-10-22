# frozen_string_literal: true

class AddTemporaryIndexOnNamespaceSettingsExperimentFeaturesEnabled < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_namespace_settings_on_experiment_features_enabled'

  def up
    # Temporary index to support EnableProjectStudioForEarlyAccessParticipants migration
    # Remove with https://gitlab.com/gitlab-org/gitlab/-/issues/578016 in 18.7 or sooner
    add_concurrent_index(
      :namespace_settings,
      :namespace_id,
      where: 'experiment_features_enabled IS TRUE',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:namespace_settings, INDEX_NAME)
  end
end
