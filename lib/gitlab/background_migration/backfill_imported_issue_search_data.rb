# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Rechedules the backfill for the `issue_search_data` table for issues imported prior
    # to the fix for the imported issues search data bug:

    class BackfillImportedIssueSearchData < BatchedMigrationJob
      SUB_BATCH_SIZE = 1_000

      operation_name :update_search_data
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          update_search_data(sub_batch)
        rescue ActiveRecord::StatementInvalid => e # rubocop:todo BackgroundMigration/AvoidSilentRescueExceptions -- https://gitlab.com/gitlab-org/gitlab/-/issues/431592
          raise unless e.cause.is_a?(PG::ProgramLimitExceeded) && e.message.include?('string is too long for tsvector')

          update_search_data_individually(sub_batch)
        end
      end

      private

      def update_search_data(relation)
        ApplicationRecord.connection.execute(
          <<~SQL
          INSERT INTO issue_search_data
          SELECT
            project_id,
            id,
            NOW(),
            NOW(),
            setweight(to_tsvector('english', LEFT(title, 255)), 'A') || setweight(to_tsvector('english', LEFT(REGEXP_REPLACE(description, '[A-Za-z0-9+/@]{50,}', ' ', 'g'), 1048576)), 'B')
          FROM (#{relation.limit(SUB_BATCH_SIZE).to_sql}) issues
          ON CONFLICT DO NOTHING
          SQL
        )
      end

      def update_search_data_individually(relation)
        relation.pluck(:id).each do |issue_id|
          update_search_data(relation.klass.where(id: issue_id))
          sleep(pause_ms * 0.001)
        rescue ActiveRecord::StatementInvalid => e # rubocop:todo BackgroundMigration/AvoidSilentRescueExceptions -- https://gitlab.com/gitlab-org/gitlab/-/issues/431592
          raise unless e.cause.is_a?(PG::ProgramLimitExceeded) && e.message.include?('string is too long for tsvector')

          logger.error(
            message: "Error updating search data: #{e.message}",
            class: relation.klass.name,
            model_id: issue_id
          )
        end
      end

      def logger
        @logger ||= Gitlab::BackgroundMigration::Logger.build
      end
    end
  end
end
