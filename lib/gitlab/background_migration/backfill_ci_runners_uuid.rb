# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiRunnersUuid < BatchedMigrationJob
      operation_name :backfill_ci_runners_uuid
      feature_category :runner_core

      def perform
        each_sub_batch do |sub_batch|
          ids = sub_batch.where(uuid: nil).pluck(:id)
          next if ids.empty?

          values_clause = ids.map do |id|
            "(#{Integer(id)}, #{connection.quote(Gitlab::Utils.uuid_v7)})"
          end.join(', ')

          connection.execute(<<~SQL)
            UPDATE ci_runners
            SET uuid = values.uuid::uuid
            FROM (VALUES #{values_clause}) AS values(id, uuid)
            WHERE ci_runners.id = values.id AND ci_runners.uuid IS NULL
          SQL
        end
      end
    end
  end
end
