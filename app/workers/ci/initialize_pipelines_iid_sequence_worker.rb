# frozen_string_literal: true

module Ci
  class InitializePipelinesIidSequenceWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :always
    feature_category :continuous_integration
    idempotent!

    def handle_event(event)
      Project.find_by_id(event.data[:project_id]).try do |project|
        next if project.internal_ids.ci_pipelines.any?

        ::Ci::Pipeline.track_project_iid!(project, 0)
      end
    end
  end
end
