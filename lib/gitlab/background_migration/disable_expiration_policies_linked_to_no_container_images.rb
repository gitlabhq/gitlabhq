# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    BATCH_SIZE = 1000

    # This background migration disables container expiration policies connected
    # to a project that has no container repositories
    class DisableExpirationPoliciesLinkedToNoContainerImages
      # rubocop: disable Style/Documentation
      class ContainerExpirationPolicy < ActiveRecord::Base
        include EachBatch

        self.table_name = 'container_expiration_policies'
      end
      # rubocop: enable Style/Documentation

      def perform(from_id, to_id)
        ContainerExpirationPolicy.where(enabled: true, project_id: from_id..to_id).each_batch(of: BATCH_SIZE) do |batch|
          sql = <<-SQL
            WITH batched_relation AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (#{batch.select(:project_id).limit(BATCH_SIZE).to_sql})
            UPDATE container_expiration_policies
            SET enabled = FALSE
            FROM batched_relation
            WHERE container_expiration_policies.project_id = batched_relation.project_id
            AND NOT EXISTS (SELECT 1 FROM "container_repositories" WHERE container_repositories.project_id = container_expiration_policies.project_id)
          SQL
          execute(sql)
        end
      end

      private

      def execute(sql)
        ActiveRecord::Base
          .connection
          .execute(sql)
      end
    end
  end
end
