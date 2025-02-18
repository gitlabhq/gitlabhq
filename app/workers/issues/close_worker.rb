# frozen_string_literal: true

module Issues
  class CloseWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    idempotent!
    deduplicate :until_executed, including_scheduled: true
    feature_category :source_code_management
    urgency :high
    weight 2

    def perform(project_id, issue_id, issue_type, params = {})
      project = Project.find_by_id(project_id)

      unless project
        logger.info(structured_payload(message: "Project not found.", project_id: project_id))
        return
      end

      issue = case issue_type
              when "ExternalIssue"
                ExternalIssue.new(issue_id, project)
              else
                Issue.find_by_id(issue_id)
              end

      unless issue
        logger.info(structured_payload(message: "Issue not found.", issue_id: issue_id))
        return
      end

      author = User.find_by_id(params["closed_by"])

      unless author
        logger.info(structured_payload(message: "Author not found.", user_id: params["closed_by"]))
        return
      end

      user = User.find_by_id(params["user_id"])

      unless user
        logger.info(structured_payload(message: "User not found.", user_id: params["user_id"]))
        return
      end

      if !issue.is_a?(ExternalIssue) && !user.can?(:update_issue, issue)
        logger.info(
          structured_payload(message: "User cannot update issue.", user_id: params["user_id"], issue_id: issue_id)
        )
        return
      end

      commit = Commit.build_from_sidekiq_hash(project, params["commit_hash"])
      service = Issues::CloseService.new(container: project, current_user: author)

      service.execute(issue, commit: commit)
    end
  end
end
