# frozen_string_literal: true

class CleanUpPendingBuildsTable < ActiveRecord::Migration[6.0]
  include ::Gitlab::Database::DynamicModelHelpers

  BATCH_SIZE = 1000

  disable_ddl_transaction!

  def up
    return unless Gitlab.dev_or_test_env? || Gitlab.com?

    each_batch_range('ci_pending_builds', of: BATCH_SIZE) do |min, max|
      execute <<~SQL
        DELETE FROM ci_pending_builds
          USING ci_builds
          WHERE ci_builds.id = ci_pending_builds.build_id
            AND ci_builds.status != 'pending'
            AND ci_builds.type = 'Ci::Build'
            AND ci_pending_builds.id BETWEEN #{min} AND #{max}
      SQL
    end
  end

  def down
    # noop
  end
end
