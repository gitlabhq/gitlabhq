# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class FixAwardEmojiNamespaceIdForIssues < BatchedMigrationJob
      operation_name :fix_award_emoji_namespace_id_for_issues
      scope_to ->(relation) { relation.where(awardable_type: 'Issue') } # rubocop:disable Database/AvoidScopeTo -- Supporting index tmp_idx_award_emoji_on_id_where_awardable_type_issue
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              WITH relation AS MATERIALIZED (
                #{sub_batch.select(:id, :awardable_id).limit(sub_batch_size).to_sql}
              )
              UPDATE "award_emoji"
              SET
                "namespace_id" = "issues"."namespace_id"
              FROM
                "relation"
                INNER JOIN "issues" ON "issues"."id" = "relation"."awardable_id"
              WHERE
                "award_emoji"."id" = "relation"."id"
            SQL
          )
        end
      end
    end
  end
end
