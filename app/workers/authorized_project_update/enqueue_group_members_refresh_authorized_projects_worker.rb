# frozen_string_literal: true

module AuthorizedProjectUpdate # rubocop:disable Gitlab/BoundedContexts -- keeping related workers in the same module
  class EnqueueGroupMembersRefreshAuthorizedProjectsWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    feature_category :permissions
    urgency :low
    data_consistency :delayed
    queue_namespace :authorized_project_update

    idempotent!
    deduplicate :until_executed, if_deduplicated: :reschedule_once, including_scheduled: true

    defer_on_database_health_signal :gitlab_main_org, [], 1.minute,
      indicators: [Gitlab::Database::HealthStatus::Indicators::WalRate]

    def self.defer_on_database_health_signal?
      Feature.enabled?(:defer_primary_auth_refresh_on_wal_rate, :instance)
    end

    def perform(group_id, params = {})
      priority = params.fetch('priority', UserProjectAccessChangedService::LOW_PRIORITY).to_sym

      return if skip_safety_net_refresh?(priority)

      group = Group.find_by_id(group_id)
      return unless group

      group.refresh_members_authorized_projects(
        priority: priority,
        direct_members_only: params.fetch('direct_members_only', false)
      )
    end

    private

    # Groups::GroupLinks services use this worker as their primary refresh path at medium priority,
    # so only the low priority safety net runs are skipped.
    def skip_safety_net_refresh?(priority)
      priority == UserProjectAccessChangedService::LOW_PRIORITY &&
        Feature.enabled?(:do_not_run_safety_net_auth_refresh_jobs, :instance)
    end
  end
end
