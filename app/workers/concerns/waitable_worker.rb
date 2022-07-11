# frozen_string_literal: true

module WaitableWorker
  extend ActiveSupport::Concern

  class_methods do
    # Schedules multiple jobs and waits for them to be completed.
    def bulk_perform_and_wait(args_list)
      # Short-circuit: it's more efficient to do small numbers of jobs inline
      if args_list.size == 1 || (args_list.size <= 3 && !inline_refresh_only_for_single_element?)
        return bulk_perform_inline(args_list)
      end

      bulk_perform_async(args_list)
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

    def inline_refresh_only_for_single_element?
      Feature.enabled?(:inline_project_authorizations_refresh_only_for_single_element)
    end
  end

  def perform(*args)
    notify_key = args.pop if Gitlab::JobWaiter.key?(args.last)

    super(*args)
  ensure
    Gitlab::JobWaiter.notify(notify_key, jid) if notify_key
  end
end
