# frozen_string_literal: true

# Restores the DB-level default on the model registry / experiments access level
# columns, undoing RemoveModelFeaturesAccessLevelDefaults (20260617130000).
#
# Those columns are NOT NULL. Dropping their default made every insert path that
# does not build a ProjectFeature through ActiveRecord (raw SQL, insert_all, bulk
# inserts such as FixProjectsWithoutProjectFeature) write NULL and trip the
# not-null constraint. Restoring the default makes all insert paths safe again.
#
# Metadata-only change in PostgreSQL: existing rows are untouched.
class RestoreModelFeaturesAccessLevelDefaults < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    change_column_default(:project_features, :model_registry_access_level, from: nil, to: 20)
    change_column_default(:project_features, :model_experiments_access_level, from: nil, to: 20)
  end
end
