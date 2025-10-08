# frozen_string_literal: true

module MergeRequests
  module Refresh
    class PipelineWorker # rubocop:disable Scalability/IdempotentWorker -- Pipeline creation isn't idempotent
      include ApplicationWorker

      deduplicate :until_executed
      feature_category :code_review_workflow
      urgency :high
      data_consistency :sticky

      # NOTE: This worker will be deprecated once we switch to using events
      def perform(project_id, user_id, oldrev, newrev, ref, params = {})
        project = Project.find_by_id(project_id)
        return unless project

        user = User.find_by_id(user_id)
        return unless user

        params ||= {}
        push_options = params.with_indifferent_access[:push_options]
        gitaly_context = params.with_indifferent_access[:gitaly_context]

        MergeRequests::Refresh::PipelineService
          .new(project: project, current_user: user, params: { push_options: push_options,
                                                               gitaly_context: gitaly_context })
          .execute(oldrev, newrev, ref)
      end
    end
  end
end
