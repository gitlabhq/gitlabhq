# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Metrics < Chain::Base
          def perform!
            increment_pipeline_created_counter
            create_snowplow_event_for_pipeline_name
          end

          def break?
            false
          end

          def increment_pipeline_created_counter
            labels = {
              source: @pipeline.source,
              partition_id: @pipeline.partition_id
            }

            ::Gitlab::Ci::Pipeline::Metrics
              .pipelines_created_counter
              .increment(labels)
          end

          def create_snowplow_event_for_pipeline_name
            return unless @pipeline.pipeline_metadata&.name

            Gitlab::Tracking.event(
              self.class.name,
              'create_pipeline_with_name',
              project: @pipeline.project,
              user: @pipeline.user,
              namespace: @pipeline.project.namespace)
          end
        end
      end
    end
  end
end
