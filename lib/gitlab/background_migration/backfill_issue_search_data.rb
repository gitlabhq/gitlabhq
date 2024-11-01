# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills the new `issue_search_data` table, which contains
    # the tsvector from the issue title and description.
    class BackfillIssueSearchData
      include Gitlab::Database::DynamicModelHelpers

      def perform(start_id, stop_id, batch_table, batch_column, sub_batch_size, pause_ms)
        define_batchable_model(batch_table, connection: ApplicationRecord.connection).where(batch_column => start_id..stop_id).each_batch(of: sub_batch_size) do |sub_batch|
          update_search_data(sub_batch)

          sleep(pause_ms * 0.001)
        rescue ActiveRecord::StatementInvalid => e
          raise unless e.cause.is_a?(PG::ProgramLimitExceeded) && e.message.include?('string is too long for tsvector')

          update_search_data_individually(sub_batch, pause_ms)
        end
      end

      private

      def update_search_data(relation)
        relation.klass.connection.execute(
          <<~SQL
          INSERT INTO issue_search_data (project_id, issue_id, search_vector, created_at, updated_at)
          SELECT
            project_id,
            id,
            setweight(to_tsvector('english', LEFT(title, 255)), 'A') || setweight(to_tsvector('english', LEFT(REGEXP_REPLACE(description, '[A-Za-z0-9+/@]{50,}', ' ', 'g'), 1048576)), 'B'),
            NOW(),
            NOW()
          FROM issues
          WHERE issues.id IN (#{relation.select(:id).to_sql})
          ON CONFLICT DO NOTHING
          SQL
        )
      end

      def update_search_data_individually(relation, pause_ms)
        relation.pluck(:id).each do |issue_id|
          update_search_data(relation.klass.where(id: issue_id))

          sleep(pause_ms * 0.001)
        rescue ActiveRecord::StatementInvalid => e
          raise unless e.cause.is_a?(PG::ProgramLimitExceeded) && e.message.include?('string is too long for tsvector')

          logger.error(
            message: 'Error updating search data: string is too long for tsvector',
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
