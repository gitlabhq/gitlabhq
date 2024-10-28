# frozen_string_literal: true

module Ci
  class UserCancelPipelineWorker
    include ApplicationWorker

    data_consistency :always
    feature_category :continuous_integration
    idempotent!
    deduplicate :until_executed
    urgency :high
    loggable_arguments 1

    def perform(pipeline_id, auto_canceled_by_pipeline_id, current_user_id, params = {}) # rubocop:disable Lint/UnusedMethodArgument -- Allowing for future expansion
      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        # cascade_to_children is false because we iterate through children
        # we also cancel bridges prior to prevent more children
        ::Ci::CancelPipelineService.new(
          pipeline: pipeline,
          current_user: User.find_by_id(current_user_id),
          cascade_to_children: true,
          auto_canceled_by_pipeline: ::Ci::Pipeline.find_by_id(auto_canceled_by_pipeline_id)
        ).execute
      end
    end
  end
end
