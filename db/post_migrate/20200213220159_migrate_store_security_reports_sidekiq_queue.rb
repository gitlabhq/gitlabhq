# frozen_string_literal: true

class MigrateStoreSecurityReportsSidekiqQueue < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'pipeline_default:store_security_reports', to: 'security_scans:store_security_reports'
  end

  def down
    sidekiq_queue_migrate 'security_scans:store_security_reports', to: 'pipeline_default:store_security_reports'
  end
end
