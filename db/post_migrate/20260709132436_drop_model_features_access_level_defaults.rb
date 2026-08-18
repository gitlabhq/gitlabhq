# frozen_string_literal: true

# Drops the DB default on project_features.model_registry_access_level and
# model_experiments_access_level so ProjectFeature#set_model_features_access_level
# supplies a visibility-based default. Metadata-only; existing rows are untouched.
class DropModelFeaturesAccessLevelDefaults < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    change_column_default(:project_features, :model_registry_access_level, from: 20, to: nil)
    change_column_default(:project_features, :model_experiments_access_level, from: 20, to: nil)
  end
end
