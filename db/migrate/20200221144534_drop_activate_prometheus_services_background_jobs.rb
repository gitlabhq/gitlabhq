# frozen_string_literal: true

class DropActivatePrometheusServicesBackgroundJobs < ActiveRecord::Migration[6.0]
  DOWNTIME = false
  DROPPED_JOB_CLASS = 'ActivatePrometheusServicesForSharedClusterApplications'.freeze
  QUEUE = 'background_migration'.freeze

  def up
    sidekiq_queues.each do |queue|
      queue.each do |job|
        klass, project_id, *should_be_empty = job.args
        next unless klass == DROPPED_JOB_CLASS && project_id.is_a?(Integer) && should_be_empty.empty?

        job.delete
      end
    end
  end

  def down
    # no-op
  end

  def sidekiq_queues
    [Sidekiq::ScheduledSet.new, Sidekiq::RetrySet.new, Sidekiq::Queue.new(QUEUE)]
  end
end
