# frozen_string_literal: true

class StealBackgroundJobForFixingConflictingProjectNamesAndPaths < Gitlab::Database::Migration[1.0]
  def up
    Gitlab::BackgroundMigration.steal('FixDuplicateProjectNameAndPath')
  end

  def down
    # no-op
  end
end
