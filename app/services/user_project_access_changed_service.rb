# frozen_string_literal: true

class UserProjectAccessChangedService
  DELAY = 1.hour

  HIGH_PRIORITY = :high
  LOW_PRIORITY = :low

  def initialize(user_ids)
    @user_ids = Array.wrap(user_ids)
  end

  def execute(blocking: true, priority: HIGH_PRIORITY)
    bulk_args = @user_ids.map { |id| [id] }

    if blocking
      AuthorizedProjectsWorker.bulk_perform_and_wait(bulk_args)
    else
      if priority == HIGH_PRIORITY
        AuthorizedProjectsWorker.bulk_perform_async(bulk_args) # rubocop:disable Scalability/BulkPerformWithContext
      else
        AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker.bulk_perform_in( # rubocop:disable Scalability/BulkPerformWithContext
          DELAY, bulk_args, batch_size: 100, batch_delay: 30.seconds)
      end
    end
  end
end

UserProjectAccessChangedService.prepend_mod_with('UserProjectAccessChangedService')
