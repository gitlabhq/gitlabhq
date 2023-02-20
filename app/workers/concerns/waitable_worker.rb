# frozen_string_literal: true

module WaitableWorker
  extend ActiveSupport::Concern

  def perform(*args)
    notify_key = args.pop if Gitlab::JobWaiter.key?(args.last)

    super(*args)
  ensure
    Gitlab::JobWaiter.notify(notify_key, jid) if notify_key
  end
end
