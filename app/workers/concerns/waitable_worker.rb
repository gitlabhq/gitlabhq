# frozen_string_literal: true

module WaitableWorker
  extend ActiveSupport::Concern

  class_methods do
    # Schedules multiple jobs and waits for them to be completed.
    def bulk_perform_and_wait(args_list)
      bulk_perform_async(args_list)
    end
  end

  def perform(*args)
    notify_key = args.pop if Gitlab::JobWaiter.key?(args.last)

    super(*args)
  ensure
    Gitlab::JobWaiter.notify(notify_key, jid) if notify_key
  end
end
