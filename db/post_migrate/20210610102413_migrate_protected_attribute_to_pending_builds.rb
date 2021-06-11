# frozen_string_literal: true

class MigrateProtectedAttributeToPendingBuilds < ActiveRecord::Migration[6.1]
  include ::Gitlab::Database::DynamicModelHelpers

  disable_ddl_transaction!

  def up
    return unless Gitlab.dev_or_test_env? || Gitlab.com?

    each_batch_range('ci_pending_builds', of: 1000) do |min, max|
      execute <<~SQL
        UPDATE ci_pending_builds
          SET protected = true
        FROM ci_builds
          WHERE ci_pending_builds.build_id = ci_builds.id
            AND ci_builds.protected = true
            AND ci_pending_builds.id BETWEEN #{min} AND #{max}
      SQL
    end
  end

  def down
    # no op
  end
end
