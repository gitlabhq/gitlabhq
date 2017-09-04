class AuthorizedProjectsWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  # Schedules multiple jobs and waits for them to be completed.
  def self.bulk_perform_and_wait(args_list)
    # Short-circuit: it's more efficient to do small numbers of jobs inline
    return bulk_perform_inline(args_list) if args_list.size <= 3

    waiter = Gitlab::JobWaiter.new(args_list.size)

    # Point all the bulk jobs at the same JobWaiter. Converts, [[1], [2], [3]]
    # into [[1, "key"], [2, "key"], [3, "key"]]
    waiting_args_list = args_list.map { |args| [*args, waiter.key] }
    bulk_perform_async(waiting_args_list)

    waiter.wait
  end

  # Schedules multiple jobs to run in sidekiq without waiting for completion
  def self.bulk_perform_async(args_list)
    Sidekiq::Client.push_bulk('class' => self, 'queue' => sidekiq_options['queue'], 'args' => args_list)
  end

  # Performs multiple jobs directly. Failed jobs will be put into sidekiq so
  # they can benefit from retries
  def self.bulk_perform_inline(args_list)
    failed = []

    args_list.each do |args|
      begin
        new.perform(*args)
      rescue
        failed << args
      end
    end

    bulk_perform_async(failed) if failed.present?
  end

  def perform(user_id, notify_key = nil)
    user = User.find_by(id: user_id)

    user&.refresh_authorized_projects
  ensure
    Gitlab::JobWaiter.notify(notify_key, jid) if notify_key
  end
end
