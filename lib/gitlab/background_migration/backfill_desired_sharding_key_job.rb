# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable BackgroundMigration/FeatureCategory -- Feature category to be specified by inheriting class
    class BackfillDesiredShardingKeyJob < BatchedMigrationJob
      job_arguments :backfill_column, :backfill_via_table, :backfill_via_column, :backfill_via_foreign_key

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.connection.execute(construct_query(sub_batch: sub_batch.where(backfill_column => nil)))
        end
      end

      def backfill_via_table_primary_key
        'id'
      end

      def construct_query(sub_batch:)
        <<~SQL
          UPDATE #{batch_table}
          SET #{backfill_column} = #{backfill_via_table}.#{backfill_via_column}
          FROM #{backfill_via_table}
          WHERE #{backfill_via_table}.#{backfill_via_table_primary_key} = #{batch_table}.#{backfill_via_foreign_key}
          AND #{batch_table}.#{batch_column} IN (#{sub_batch.select(batch_column).to_sql})
        SQL
      end
    end
    # rubocop: enable BackgroundMigration/FeatureCategory
  end
end
