# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BatchedMigrationBaseClass -- This is indirectly deriving from the correct base class
    class BackfillPartitionedProjectDailyStatistics < BackfillPartitionedTable
      # No overrides needed - inherits all standard backfill behavior
    end
    # rubocop: enable Migration/BatchedMigrationBaseClass
  end
end
