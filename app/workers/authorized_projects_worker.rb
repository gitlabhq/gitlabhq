class AuthorizedProjectsWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  # Schedules multiple jobs and waits for them to be completed.
  def self.bulk_perform_and_wait(args_list)
    job_ids = bulk_perform_async(args_list)

    Gitlab::JobWaiter.new(job_ids).wait
  end

  def self.bulk_perform_async(args_list)
    Sidekiq::Client.push_bulk('class' => self, 'args' => args_list)
  end

  def perform(user_id)
    user = User.find_by(id: user_id)

    user&.refresh_authorized_projects
  end
end
