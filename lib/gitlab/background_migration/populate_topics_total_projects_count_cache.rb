# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    SUB_BATCH_SIZE = 1_000

    # The class to populates the total projects counter cache of topics
    class PopulateTopicsTotalProjectsCountCache
      # Temporary AR model for topics
      class Topic < ActiveRecord::Base
        include EachBatch

        self.table_name = 'topics'
      end

      def perform(start_id, stop_id)
        Topic.where(id: start_id..stop_id).each_batch(of: SUB_BATCH_SIZE) do |batch|
          ApplicationRecord.connection.execute(<<~SQL)
            WITH batched_relation AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (#{batch.select(:id).limit(SUB_BATCH_SIZE).to_sql})
            UPDATE topics
            SET total_projects_count = (SELECT COUNT(*) FROM project_topics WHERE topic_id = batched_relation.id)
            FROM batched_relation
            WHERE topics.id = batched_relation.id
          SQL
        end
      end
    end
  end
end
