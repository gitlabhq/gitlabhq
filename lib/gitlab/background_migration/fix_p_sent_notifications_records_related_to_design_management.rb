# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class FixPSentNotificationsRecordsRelatedToDesignManagement < BatchedMigrationJob
      operation_name :fix_namespace_id_design_management_records
      scope_to ->(relation) { relation.where(noteable_type: 'DesignManagement::Design') } # rubocop:disable Database/AvoidScopeTo -- Supporting index tmp_idx_p_sent_notifications_on_id_for_designs
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              WITH relation AS (
                #{sub_batch.select(:id, :noteable_id).limit(sub_batch_size).to_sql}
              )
              UPDATE "p_sent_notifications"
              SET
                "namespace_id" = "design_management_designs"."namespace_id"
              FROM
                "relation"
                INNER JOIN "design_management_designs" ON "design_management_designs"."id" = "relation"."noteable_id"
              WHERE
                "p_sent_notifications"."id" = "relation"."id"
            SQL
          )
        end
      end
    end
  end
end
