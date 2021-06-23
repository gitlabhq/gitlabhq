# frozen_string_literal: true

module WaitableWorker
  extend ActiveSupport::Concern

  class_methods do
    # Schedules multiple jobs and waits for them to be completed.
    def bulk_perform_and_wait(args_list, timeout: 10)
      # Short-circuit: it's more efficient to do small numbers of jobs inline
      return bulk_perform_inline(args_list) if args_list.size <= 3

      # Don't wait if there's too many jobs to be waited for. Not including the
      # waiter allows them to be deduplicated and it skips waiting for jobs that
      # are not likely to finish within the timeout. This assumes we can process
      # 10 jobs per second:
      # https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/205
      return bulk_perform_async(args_list) if args_list.length >= 10 * timeout

      waiter = Gitlab::JobWaiter.new(args_list.size, worker_label: self.to_s)

      # Point all the bulk jobs at the same JobWaiter. Converts, [[1], [2], [3]]
      # into [[1, "key"], [2, "key"], [3, "key"]]
      waiting_args_list = args_list.map { |args| [*args, waiter.key] }
      bulk_perform_async(waiting_args_list)

      waiter.wait(timeout)
    end

    # Performs multiple jobs directly. Failed jobs will be put into sidekiq so
    # they can benefit from retries
    def bulk_perform_inline(args_list)
      failed = []

      args_list.each do |args|
        worker = new
        Gitlab::AppJsonLogger.info(worker.structured_payload(message: 'running inline'))
        worker.perform(*args)
      rescue StandardError
        failed << args
      end

      bulk_perform_async(failed) if failed.present?
    end
  end

  def perform(*args)
    notify_key = args.pop if Gitlab::JobWaiter.key?(args.last)

    super(*args)
  ensure
    Gitlab::JobWaiter.notify(notify_key, jid) if notify_key
  end
end
