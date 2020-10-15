# frozen_string_literal: true

class DropBackfillJiraTrackerDeploymentTypeJobs < ActiveRecord::Migration[6.0]
  DOWNTIME = false
  DROPPED_JOB_CLASS = 'BackfillJiraTrackerDeploymentType'.freeze
  QUEUE = 'background_migration'.freeze

  def up
    sidekiq_queues.each do |queue|
      queue.each do |job|
        next unless job.args.first == DROPPED_JOB_CLASS

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
