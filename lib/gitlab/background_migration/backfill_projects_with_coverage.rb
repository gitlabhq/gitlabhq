# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill project_ci_feature_usages for a range of projects with coverage
    class BackfillProjectsWithCoverage
      class ProjectCiFeatureUsage < ActiveRecord::Base # rubocop:disable Style/Documentation
        self.table_name = 'project_ci_feature_usages'
      end

      COVERAGE_ENUM_VALUE = 1
      INSERT_DELAY_SECONDS = 0.1

      def perform(start_id, end_id, sub_batch_size)
        report_results = ActiveRecord::Base.connection.execute <<~SQL
          SELECT DISTINCT project_id, default_branch
          FROM ci_daily_build_group_report_results
          WHERE id BETWEEN #{start_id} AND #{end_id}
        SQL

        report_results.to_a.in_groups_of(sub_batch_size, false) do |batch|
          ProjectCiFeatureUsage.insert_all(build_values(batch))

          sleep INSERT_DELAY_SECONDS
        end
      end

      private

      def build_values(batch)
        batch.map do |data|
          {
            project_id: data['project_id'],
            feature: COVERAGE_ENUM_VALUE,
            default_branch: data['default_branch']
          }
        end
      end
    end
  end
end
