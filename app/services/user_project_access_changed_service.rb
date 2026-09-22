# frozen_string_literal: true

class UserProjectAccessChangedService
  DELAY = 1.hour
  MEDIUM_DELAY = 1.minute

  HIGH_PRIORITY = :high
  MEDIUM_PRIORITY = :medium
  LOW_PRIORITY = :low

  SAFETY_NET_REFRESH_PURPOSE = 'safety_net'

  def initialize(user_ids)
    @user_ids = Array.wrap(user_ids)
  end

  def execute(priority: HIGH_PRIORITY)
    return if @user_ids.empty?

    bulk_args = @user_ids.map { |id| [id] }

    case priority
    when HIGH_PRIORITY
      AuthorizedProjectsWorker.bulk_perform_async(bulk_args) # rubocop:disable Scalability/BulkPerformWithContext
      ::User.sticking.bulk_stick(:user, @user_ids)
    when MEDIUM_PRIORITY
      AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker.bulk_perform_in(MEDIUM_DELAY, bulk_args, batch_size: 100, batch_delay: 30.seconds) # rubocop:disable Scalability/BulkPerformWithContext
    when LOW_PRIORITY
      execute_low_priority_refresh
    end
  end

  private

  def execute_low_priority_refresh
    return if Feature.enabled?(:do_not_run_safety_net_auth_refresh_jobs, :instance)

    # The actor is the user being refreshed, so each user is on exactly one path.
    db_queued_user_ids, legacy_user_ids = @user_ids.partition do |user_id|
      Feature.enabled?(:use_db_to_queue_safety_net_auth_refresh, ::User.actor_from_id(user_id))
    end

    # Legacy path first so a failure in the newer queue path cannot block it.
    enqueue_legacy_safety_net_jobs(legacy_user_ids) if legacy_user_ids.any?
    Authz::ProjectAuthorizationReverification.queue_users(db_queued_user_ids) if db_queued_user_ids.any?
  end

  def enqueue_legacy_safety_net_jobs(user_ids)
    bulk_args = user_ids.map { |id| [id] }

    Gitlab::ApplicationContext.with_raw_context(
      authorized_projects_refresh_purpose: SAFETY_NET_REFRESH_PURPOSE
    ) do
      # rubocop:disable Scalability/BulkPerformWithContext -- related_class context is set by the wrapping block
      with_related_class_context do
        AuthorizedProjectUpdate::UserRefreshFromReplicaWorker.bulk_perform_in(
          DELAY, bulk_args, batch_size: 100, batch_delay: 30.seconds)
      end
      # rubocop:enable Scalability/BulkPerformWithContext
    end
  end

  def with_related_class_context(&block)
    current_caller_id = Gitlab::ApplicationContext.current_context_attribute('meta.caller_id').presence
    Gitlab::ApplicationContext.with_context(related_class: current_caller_id, &block)
  end
end
