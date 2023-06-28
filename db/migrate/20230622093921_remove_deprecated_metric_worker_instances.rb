# frozen_string_literal: true

class RemoveDeprecatedMetricWorkerInstances < Gitlab::Database::Migration[2.1]
  DEPRECATED_JOB_CLASSES = %w[
    Clusters::Integrations::CheckPrometheusHealthWorker
    Metrics::Dashboard::PruneOldAnnotationsWorker
    Metrics::Dashboard::ScheduleAnnotationsPruneWorker
    Metrics::Dashboard::SyncDashboardsWorker
  ]

  disable_ddl_transaction!

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
