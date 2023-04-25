# frozen_string_literal: true

class RemoveDanglingRunningBuilds < Gitlab::Database::Migration[1.0]
  BATCH_SIZE = 100

  disable_ddl_transaction!

  def up
    each_batch_range('ci_running_builds', of: BATCH_SIZE) do |min, max|
      execute <<~SQL
        DELETE FROM ci_running_builds
          USING ci_builds
          WHERE ci_builds.id = ci_running_builds.build_id
            AND ci_builds.status = 'failed'
            AND ci_builds.type = 'Ci::Build'
            AND ci_running_builds.id BETWEEN #{min} AND #{max}
      SQL
    end
  end

  def down
    # no-op
    # This migration deletes data and it can not be reversed
  end
end
