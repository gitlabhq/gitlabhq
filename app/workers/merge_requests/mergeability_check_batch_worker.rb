# frozen_string_literal: true

module MergeRequests
  class MergeabilityCheckBatchWorker
    include ApplicationWorker
    include Gitlab::Utils::StrongMemoize

    data_consistency :sticky

    sidekiq_options retry: 3

    feature_category :code_review_workflow
    worker_resource_boundary :cpu
    idempotent!

    def logger
      @logger ||= Sidekiq.logger
    end

    def perform(merge_request_ids, user_id)
      user = User.find_by_id(user_id)
      return unless user

      # rubocop: disable CodeReuse/ActiveRecord -- doesn't seem useful to move to model
      merge_requests = MergeRequest.id_in(merge_request_ids).preload(target_project: :project_feature)
      # rubocop: enable CodeReuse/ActiveRecord

      projects = merge_requests.map(&:target_project).uniq

      Preloaders::ProjectPolicyPreloader.new(projects, user).execute

      allowed_merge_requests = merge_requests.reject do |merge_request|
        merge_status_recheck_not_allowed?(merge_request.project, user)
      end

      MergeRequest.batch_mark_as_checking(allowed_merge_requests.map(&:id))

      allowed_merge_requests.each do |merge_request|
        result = merge_request.check_mergeability

        next unless result&.error?

        logger.error(
          worker: self.class.name,
          message: "Failed to check mergeability of merge request: #{result.message}",
          merge_request_id: merge_request.id
        )
      end
    end

    private

    def merge_status_recheck_not_allowed?(project, user)
      strong_memoize_with(:merge_status_recheck_not_allowed, project.id, user.id) do
        !Ability.allowed?(user, :update_merge_request, project)
      end
    end
  end
end
