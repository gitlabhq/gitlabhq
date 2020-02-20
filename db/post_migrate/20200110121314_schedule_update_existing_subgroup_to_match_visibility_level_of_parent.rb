# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ScheduleUpdateExistingSubgroupToMatchVisibilityLevelOfParent < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'UpdateExistingSubgroupToMatchVisibilityLevelOfParent'
  DELAY_INTERVAL = 5.minutes.to_i
  BATCH_SIZE = 1000
  VISIBILITY_LEVELS = {
    internal: 10,
    private: 0
  }

  disable_ddl_transaction!

  def up
    offset = update_groups(VISIBILITY_LEVELS[:internal])
    update_groups(VISIBILITY_LEVELS[:private], offset: offset)
  end

  def down
    # no-op
  end

  private

  def update_groups(level, offset: 0)
    groups = exec_query <<~SQL
      SELECT id
      FROM namespaces
      WHERE visibility_level = #{level}
      AND type = 'Group'
      AND EXISTS (SELECT 1
                  FROM namespaces AS children
                  WHERE children.parent_id = namespaces.id)
    SQL

    ids = groups.rows.flatten

    iterator = 1

    ids.in_groups_of(BATCH_SIZE, false) do |batch_of_ids|
      delay = DELAY_INTERVAL * (iterator + offset)
      BackgroundMigrationWorker.perform_in(delay, MIGRATION, [batch_of_ids, level])
      iterator += 1
    end

    say("Background jobs for visibility level #{level} scheduled in #{iterator} iterations")

    offset + iterator
  end
end
