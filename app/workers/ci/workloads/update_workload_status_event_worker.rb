# frozen_string_literal: true

module Ci
  module Workloads
    # rubocop: disable Scalability/IdempotentWorker -- EventStore::Subscriber includes idempotent
    class UpdateWorkloadStatusEventWorker
      include Gitlab::EventStore::Subscriber

      feature_category :continuous_integration
      data_consistency :delayed

      def handle_event(event)
        pipeline = Ci::Pipeline.find_by_id(event.data[:pipeline_id])
        return unless pipeline

        workload = pipeline.workload
        return unless workload

        event.data[:status].to_sym == :success ? workload.finish! : workload.drop!
      end
    end
    # rubocop: enable Scalability/IdempotentWorker
  end
end
