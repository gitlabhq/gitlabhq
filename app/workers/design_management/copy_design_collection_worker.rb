# frozen_string_literal: true

module DesignManagement
  class CopyDesignCollectionWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :design_management
    idempotent!
    urgency :low

    def perform(user_id, issue_id, target_issue_id)
      user = User.find(user_id)
      issue = Issue.find(issue_id)
      target_issue = Issue.find(target_issue_id)

      response = DesignManagement::CopyDesignCollection::CopyService.new(
        target_issue.project,
        user,
        issue: issue,
        target_issue: target_issue
      ).execute

      Gitlab::AppLogger.warn(response.message) if response.error?
    end
  end
end
