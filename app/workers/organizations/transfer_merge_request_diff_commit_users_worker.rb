# frozen_string_literal: true

module Organizations
  class TransferMergeRequestDiffCommitUsersWorker
    include ApplicationWorker

    data_consistency :sticky
    deduplicate :until_executed
    idempotent!
    feature_category :code_review_workflow
    urgency :low
    loggable_arguments 0, 1, 2
    sidekiq_options max_retries_after_interruption: 10
    concurrency_limit -> { 10 }

    defer_on_database_health_signal :gitlab_main, [:merge_request_diff_commit_users, :merge_request_commits_metadata],
      1.minute

    MAX_RUNTIME = 3.minutes
    REQUEUE_DELAY = 2.minutes

    def perform(group_id, old_organization_id, new_organization_id, cursor = nil)
      group = ::Group.find_by_id(group_id)
      unless group
        logger.info(structured_payload(message: 'Group not found.', group_id: group_id))
        return
      end

      old_organization = ::Organizations::Organization.find_by_id(old_organization_id)
      unless old_organization
        logger.info(structured_payload(message: 'Old organization not found.', organization_id: old_organization_id))
        return
      end

      new_organization = ::Organizations::Organization.find_by_id(new_organization_id)
      unless new_organization
        logger.info(structured_payload(message: 'New organization not found.', organization_id: new_organization_id))
        return
      end

      service = ::Organizations::DataSeverance::MergeRequestDiffCommitUsersService.new(
        group: group,
        old_organization: old_organization,
        new_organization: new_organization
      )

      runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)

      service.execute(cursor: cursor) do |last_project_id|
        if runtime_limiter.over_time?
          self.class.perform_in(REQUEUE_DELAY, group_id, old_organization_id, new_organization_id, last_project_id)
          break
        end
      end
    end
  end
end
