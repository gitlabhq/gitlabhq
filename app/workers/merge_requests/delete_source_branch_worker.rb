# frozen_string_literal: true

class MergeRequests::DeleteSourceBranchWorker
  include ApplicationWorker

  LEASE_KEY_PREFIX = 'branch_pending_deletion'
  LEASE_TIMEOUT = 5.minutes.to_i

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :code_review_workflow
  urgency :high
  idempotent!

  def self.lease_key(project_id, branch_name)
    "#{LEASE_KEY_PREFIX}:#{project_id}:#{branch_name}"
  end

  def perform(merge_request_id, source_branch_sha, user_id)
    merge_request = MergeRequest.find_by_id(merge_request_id)
    user = User.find_by_id(user_id)

    return unless merge_request && user
    # Source branch changed while it's being removed
    return if merge_request.source_branch_sha != source_branch_sha

    ::MergeRequests::RetargetChainService.new(project: merge_request.source_project, current_user: user)
            .execute(merge_request)

    ::Projects::DeleteBranchWorker.new.perform(merge_request.source_project.id, user.id, merge_request.source_branch)

    release_branch_deletion_lease(merge_request)
  end

  private

  def release_branch_deletion_lease(merge_request)
    lease_key = self.class.lease_key(merge_request.source_project_id, merge_request.source_branch)
    uuid = Gitlab::ExclusiveLease.get_uuid(lease_key)
    return unless uuid

    Gitlab::ExclusiveLease.cancel(lease_key, uuid)
  end
end
