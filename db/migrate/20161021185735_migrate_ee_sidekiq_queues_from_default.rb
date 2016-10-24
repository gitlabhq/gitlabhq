# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateEeSidekiqQueuesFromDefault < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true

  DOWNTIME_REASON = <<-EOF
  Moving Sidekiq jobs from queues requires Sidekiq to be stopped. Not stopping
  Sidekiq will result in the loss of jobs that are scheduled after this
  migration completes.
  EOF

  disable_ddl_transaction!

  # Jobs for which the queue names have been changed (e.g. multiple workers
  # using the same non-default queue).
  #
  # The keys are the old queue names, the values the jobs to move and their new
  # queue names.
  RENAMED_QUEUES = {
    default: {
      'LdapGroupSyncWorker' => :cronjob,
      'LdapSyncWorker'      => :cronjob,
    }
  }

  def up
    Sidekiq.redis do |redis|
      RENAMED_QUEUES.each do |queue, jobs|
        migrate_from_queue(redis, queue, jobs)
      end
    end
  end

  def down
    Sidekiq.redis do |redis|
      RENAMED_QUEUES.each do |dest_queue, jobs|
        jobs.each do |worker, from_queue|
          migrate_from_queue(redis, from_queue, worker => dest_queue)
        end
      end
    end
  end

  def migrate_from_queue(redis, queue, job_mapping)
    while job = redis.lpop("queue:#{queue}")
      payload = JSON.load(job)
      new_queue = job_mapping[payload['class']]

      # If we have no target queue to migrate to we're probably dealing with
      # some ancient job for which the worker no longer exists. In that case
      # there's no sane option we can take, other than just dropping the job.
      next unless new_queue

      payload['queue'] = new_queue

      redis.lpush("queue:#{new_queue}", JSON.dump(payload))
    end
  end
end
