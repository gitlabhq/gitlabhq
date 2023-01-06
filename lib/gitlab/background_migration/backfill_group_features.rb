# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill group_features for an array of groups
    class BackfillGroupFeatures < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      job_arguments :batch_size
      operation_name :upsert_group_features
      feature_category :database

      def perform
        each_sub_batch(
          batching_arguments: { order_hint: :type },
          batching_scope: ->(relation) { relation.where(type: 'Group') }
        ) do |sub_batch|
          upsert_group_features(sub_batch)
        end
      end

      private

      def upsert_group_features(relation)
        connection.execute(
          <<~SQL
          INSERT INTO group_features (group_id, created_at, updated_at)
          SELECT namespaces.id as group_id, now(), now()
          FROM namespaces
          WHERE namespaces.type = 'Group' AND namespaces.id IN(#{relation.select(:id).limit(batch_size).to_sql})
          ON CONFLICT (group_id) DO NOTHING;
          SQL
        )
      end
    end
  end
end
