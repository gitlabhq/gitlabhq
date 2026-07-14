# frozen_string_literal: true

# Disabled (no-op).
#
# This migration originally dropped the DB-level default on
# project_features.model_registry_access_level and model_experiments_access_level.
# Combined with partial_inserts, nodes running the previous release omitted those
# columns from inserts and relied on the default, so once it was gone they wrote
# NULL into NOT NULL columns and raised PG::NotNullViolation, breaking project
# creation during the rolling deploy. See the incident and !242424.
#
# It is left as a no-op (per the deleting migrations guidance) so the default is
# never dropped on environments where it has not yet run. On environments where
# it already ran, the default is restored by
# 20260624225217_restore_model_features_access_level_defaults.
class RemoveModelFeaturesAccessLevelDefaults < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    # no-op
  end

  def down
    # no-op
  end
end
