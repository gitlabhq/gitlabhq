class CalculateConvDevIndexPercentages < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  class ConversationalDevelopmentIndexMetric < ActiveRecord::Base
    self.table_name = 'conversational_development_index_metrics'

    METRICS = %w[boards ci_pipelines deployments environments issues merge_requests milestones notes
                 projects_prometheus_active service_desk_issues]
  end

  def up
    ConversationalDevelopmentIndexMetric.find_each do |conv_dev_index|
      update = []

      ConversationalDevelopmentIndexMetric::METRICS.each do |metric|
        instance_score = conv_dev_index["instance_#{metric}"].to_f
        leader_score = conv_dev_index["leader_#{metric}"].to_f

        percentage = leader_score.zero? ? 0.0 : (instance_score / leader_score) * 100
        update << "percentage_#{metric} = '#{percentage}'"
      end

      execute("UPDATE conversational_development_index_metrics SET #{update.join(',')} WHERE id = #{conv_dev_index.id}")
    end
  end

  def down
  end
end
