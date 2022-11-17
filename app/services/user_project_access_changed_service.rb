# frozen_string_literal: true

class UserProjectAccessChangedService
  DELAY = 1.hour
  MEDIUM_DELAY = 10.minutes

  HIGH_PRIORITY = :high
  MEDIUM_PRIORITY = :medium
  LOW_PRIORITY = :low

  def initialize(user_ids)
    @user_ids = Array.wrap(user_ids)
  end

  def execute(blocking: true, priority: HIGH_PRIORITY)
    return if @user_ids.empty?

    bulk_args = @user_ids.map { |id| [id] }

    result =
      if blocking
        AuthorizedProjectsWorker.bulk_perform_and_wait(bulk_args)
      else
        case priority
        when HIGH_PRIORITY
          AuthorizedProjectsWorker.bulk_perform_async(bulk_args) # rubocop:disable Scalability/BulkPerformWithContext
        when MEDIUM_PRIORITY
          AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker.bulk_perform_in(MEDIUM_DELAY, bulk_args, batch_size: 100, batch_delay: 30.seconds) # rubocop:disable Scalability/BulkPerformWithContext
        else
          with_related_class_context do
            # We wrap the execution in `with_related_class_context`so as to obtain
            # the location of the original caller
            # in jobs enqueued from within `AuthorizedProjectUpdate::UserRefreshFromReplicaWorker`
            AuthorizedProjectUpdate::UserRefreshFromReplicaWorker.bulk_perform_in( # rubocop:disable Scalability/BulkPerformWithContext
              DELAY, bulk_args, batch_size: 100, batch_delay: 30.seconds)
          end
        end
      end

    ::User.sticking.bulk_stick(:user, @user_ids)

    result
  end

  private

  def with_related_class_context(&block)
    current_caller_id = Gitlab::ApplicationContext.current_context_attribute('meta.caller_id').presence
    Gitlab::ApplicationContext.with_context(related_class: current_caller_id, &block)
  end
end
