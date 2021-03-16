# frozen_string_literal: true

class MigrateUsageTrendsSidekiqQueue < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    sidekiq_queue_migrate 'cronjob:analytics_instance_statistics_count_job_trigger', to: 'cronjob:analytics_usage_trends_count_job_trigger'
    sidekiq_queue_migrate 'analytics_instance_statistics_counter_job', to: 'analytics_usage_trends_counter_job'
  end

  def down
    sidekiq_queue_migrate 'cronjob:analytics_usage_trends_count_job_trigger', to: 'cronjob:analytics_instance_statistics_count_job_trigger'
    sidekiq_queue_migrate 'analytics_usage_trends_counter_job', to: 'analytics_instance_statistics_counter_job'
  end
end
