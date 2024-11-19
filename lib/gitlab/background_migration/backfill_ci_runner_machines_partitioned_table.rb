# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration to copy only valid data from ci_runner_machines to its corresponding partitioned table
    # rubocop: disable Migration/BatchedMigrationBaseClass -- This is indirectly deriving from the correct base class
    class BackfillCiRunnerMachinesPartitionedTable < BackfillPartitionedTable
      extend ::Gitlab::Utils::Override

      private

      override :filter_sub_batch_content
      def filter_sub_batch_content(relation)
        relation.where(runner_type: 1).or(relation.where.not(sharding_key_id: nil))
      end
    end
    # rubocop: enable Migration/BatchedMigrationBaseClass
  end
end
