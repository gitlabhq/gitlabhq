# frozen_string_literal: true

class DropBackgroundMigrationJobs < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DROPPED_JOB_CLASS = 'ActivatePrometheusServicesForSharedClusterApplications'
  QUEUE = 'background_migration'

  def up
    Sidekiq::Queue.new(QUEUE).each do |job|
      klass, project_id, *should_be_empty = job.args
      next unless klass == DROPPED_JOB_CLASS && project_id.is_a?(Integer) && should_be_empty.empty?

      job.delete
    end
  end
end
