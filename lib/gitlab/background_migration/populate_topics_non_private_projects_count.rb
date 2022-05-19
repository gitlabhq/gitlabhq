# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # The class to populates the non private projects counter of topics
    class PopulateTopicsNonPrivateProjectsCount
      SUB_BATCH_SIZE = 100

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
            SET non_private_projects_count = (
              SELECT COUNT(*) 
              FROM project_topics 
              INNER JOIN projects 
              ON project_topics.project_id = projects.id 
              WHERE project_topics.topic_id = batched_relation.id 
              AND projects.visibility_level > 0
            )
            FROM batched_relation
            WHERE topics.id = batched_relation.id
          SQL
        end
      end
    end
  end
end
