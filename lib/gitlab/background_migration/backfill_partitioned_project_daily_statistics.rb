# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BatchedMigrationBaseClass -- This is indirectly deriving from the correct base class
    class BackfillPartitionedProjectDailyStatistics < BackfillPartitionedTable
      extend ::Gitlab::Utils::Override

      private

      override :filter_sub_batch_content
      def filter_sub_batch_content(relation)
        relation.unscoped.where(id: relation.select(:id).limit(sub_batch_size))
                .where(date: 3.months.ago.beginning_of_month..)
                .limit(sub_batch_size)
      end
    end
    # rubocop: enable Migration/BatchedMigrationBaseClass
  end
end
