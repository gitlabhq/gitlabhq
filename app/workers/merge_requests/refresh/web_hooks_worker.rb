# frozen_string_literal: true

module MergeRequests
  module Refresh
    class WebHooksWorker # rubocop:disable Scalability/IdempotentWorker -- Web hooks aren't idempotent
      include ApplicationWorker

      deduplicate :until_executed
      feature_category :code_review_workflow
      urgency :low
      data_consistency :sticky
      worker_has_external_dependencies!

      defer_on_database_health_signal :gitlab_main, [], 10.seconds

      # NOTE: This worker will be deprecated once we switch to using events
      def perform(project_id, user_id, oldrev, newrev, ref)
        project = Project.find_by_id(project_id)
        return unless project

        user = User.find_by_id(user_id)
        return unless user

        MergeRequests::Refresh::WebHooksService
          .new(project: project, current_user: user)
          .execute(oldrev, newrev, ref)
      end
    end
  end
end
