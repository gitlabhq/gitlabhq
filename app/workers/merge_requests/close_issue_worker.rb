# frozen_string_literal: true

module MergeRequests
  class CloseIssueWorker
    include ApplicationWorker

    data_consistency :always
    feature_category :code_review_workflow
    urgency :low
    idempotent!

    # Issues:CloseService execute webhooks which are treated as external dependencies
    worker_has_external_dependencies!

    # This worker only accepts ID of an Issue. We are intentionally using this
    # worker to close Issues asynchronously as we only experience SQL timeouts
    # when closing an Issue.
    def perform(project_id, user_id, issue_id, merge_request_id, params = {})
      project = Project.find_by_id(project_id)

      unless project
        logger.info(structured_payload(message: 'Project not found.', project_id: project_id))
        return
      end

      user = User.find_by_id(user_id)

      unless user
        logger.info(structured_payload(message: 'User not found.', user_id: user_id))
        return
      end

      issue = Issue.find_by_id(issue_id)

      unless issue
        logger.info(structured_payload(message: 'Issue not found.', issue_id: issue_id))
        return
      end

      merge_request = MergeRequest.find_by_id(merge_request_id)

      unless merge_request
        logger.info(structured_payload(message: 'Merge request not found.', merge_request_id: merge_request_id))
        return
      end

      Issues::CloseService
        .new(container: project, current_user: user)
        .execute(
          issue,
          commit: merge_request,
          skip_authorization: !!params.with_indifferent_access[:skip_authorization]
        )
    end
  end
end
