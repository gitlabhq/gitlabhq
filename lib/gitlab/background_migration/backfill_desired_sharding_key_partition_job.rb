# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDesiredShardingKeyPartitionJob < BackfillDesiredShardingKeyJob
      job_arguments :backfill_column,
        :backfill_via_table,
        :backfill_via_column,
        :backfill_via_foreign_key,
        :partition_column

      def construct_query(sub_batch:)
        <<~SQL
          UPDATE #{batch_table}
          SET #{backfill_column} = #{backfill_via_table}.#{backfill_via_column}
          FROM #{backfill_via_table}
          WHERE #{backfill_via_table}.id = #{batch_table}.#{backfill_via_foreign_key}
          AND #{backfill_via_table}.#{partition_column} = #{batch_table}.#{partition_column}
          AND #{batch_table}.#{batch_column} IN (#{sub_batch.select(batch_column).to_sql})
        SQL
      end
    end
  end
end
