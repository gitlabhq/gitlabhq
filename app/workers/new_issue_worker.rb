# frozen_string_literal: true

class NewIssueWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include NewIssuable

  feature_category :team_planning
  urgency :high
  worker_resource_boundary :cpu
  weight 2

  attr_reader :issuable_class

  def perform(issue_id, user_id, issuable_class = 'Issue')
    @issuable_class = issuable_class.constantize

    return unless objects_found?(issue_id, user_id)

    ::EventCreateService.new.open_issue(issuable, user)
    ::NotificationService.new.new_issue(issuable, user)

    issuable.create_cross_references!(user)

    Issues::AfterCreateService
      .new(container: issuable.project, current_user: user)
      .execute(issuable)
  end
end
