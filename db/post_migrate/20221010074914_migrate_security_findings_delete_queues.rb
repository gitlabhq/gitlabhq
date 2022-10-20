# frozen_string_literal: true

class MigrateSecurityFindingsDeleteQueues < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  def up
    sidekiq_queue_migrate 'security_findings_delete_by_job_id', to: 'security_scans_purge_by_job_id'
    sidekiq_queue_migrate 'cronjob:security_findings_cleanup', to: 'cronjob:security_scans_purge'
  end

  def down
    sidekiq_queue_migrate 'security_scans_purge_by_job_id', to: 'security_findings_delete_by_job_id'
    sidekiq_queue_migrate 'cronjob:security_scans_purge', to: 'cronjob:security_findings_cleanup'
  end
end
