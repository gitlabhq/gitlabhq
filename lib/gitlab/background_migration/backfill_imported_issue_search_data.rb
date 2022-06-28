# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    # Backfills the `issue_search_data` table for issues imported prior
    # to the fix for the imported issues search data bug:
    #  https://gitlab.com/gitlab-org/gitlab/-/issues/361219
    class BackfillImportedIssueSearchData < BatchedMigrationJob
      def perform
        each_sub_batch(
          operation_name: :update_search_data,
          batching_scope: -> (relation) { Issue }
        ) do |sub_batch|
          update_search_data(sub_batch)
        rescue ActiveRecord::StatementInvalid => e
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
          FROM issues
          WHERE issues.id IN (#{relation.select(:id).to_sql})
          ON CONFLICT DO NOTHING
          SQL
        )
      end

      def update_search_data_individually(relation)
        relation.pluck(:id).each do |issue_id|
          update_search_data(relation.klass.where(id: issue_id))
          sleep(pause_ms * 0.001)
        rescue ActiveRecord::StatementInvalid => e
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
