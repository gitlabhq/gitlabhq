# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class UpdateBadgesRowsWithMulticolumnShardingKeyColumns < BatchedMigrationJob
      operation_name :update_badges_with_multicolumn_sharding_key
      feature_category :groups_and_projects

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where.not(group_id: nil)
            .where.not(project_id: nil)
            .update_all(group_id: nil)
        end
      end
    end
  end
end
