# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RecalculateDoraDeploymentFrequencyScore < BatchedMigrationJob
      operation_name :recalculate_dora_df_score
      feature_category :dora_metrics

      SCORE_BOUNDARIES = { low: 0.033, high: 1.0 }.freeze

      class DailyMetric < ApplicationRecord
        self.table_name = 'dora_daily_metrics'
      end

      class Environment < ApplicationRecord
        self.table_name = 'environments'
      end

      def perform
        each_sub_batch do |sub_batch|
          sub_batch_score_groups(sub_batch).each do |score, group|
            sub_batch.where(id: group.map(&:last)).update_all(deployment_frequency: score)
          end
        end
      end

      private

      def sub_batch_score_groups(sub_batch)
        sub_batch.map { |row| [recalculate_df_score(row), row.id] }.group_by(&:first)
      end

      def recalculate_df_score(row)
        from = row.date.beginning_of_month
        to = row.date.end_of_month
        prods = Environment.where(project_id: row.project_id).where(tier: 0)

        data = DailyMetric.where(environment_id: prods)
                          .where(date: from..to)
                          .select('SUM(deployment_frequency) as deployments_count').take

        deployment_frequency = (data['deployments_count'] || 0) / (to - from + 1).to_f

        frequency_score(deployment_frequency)
      end

      def frequency_score(value)
        return 10 if value < SCORE_BOUNDARIES[:low]
        return 30 if value > SCORE_BOUNDARIES[:high]

        20
      end
    end
  end
end
