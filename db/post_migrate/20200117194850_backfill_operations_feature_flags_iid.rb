# frozen_string_literal: true

class BackfillOperationsFeatureFlagsIid < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  ###
  # This should update about 700 rows on gitlab.com
  # Execution time is predicted to take less than a second based on #database-lab results
  # https://gitlab.com/gitlab-org/gitlab/merge_requests/22175#migration-performance
  ###
  def up
    execute('LOCK operations_feature_flags IN ACCESS EXCLUSIVE MODE')

    backfill_iids('operations_feature_flags')

    change_column_null :operations_feature_flags, :iid, false
  end

  def down
    change_column_null :operations_feature_flags, :iid, true
  end
end
