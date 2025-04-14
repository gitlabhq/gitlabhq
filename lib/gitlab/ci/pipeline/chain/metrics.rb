# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Metrics < Chain::Base
          include Gitlab::InternalEventsTracking

          def perform!
            increment_pipeline_created_counter
            create_snowplow_event_for_pipeline_name
            track_inputs_usage
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

          def track_inputs_usage
            return unless command.inputs.present?

            track_internal_event(
              'create_pipeline_with_inputs',
              project: @pipeline.project,
              user: @pipeline.user,
              additional_properties: {
                label: @pipeline.source,
                property: @pipeline.config_source,
                value: command.inputs.size
              }
            )
          end
        end
      end
    end
  end
end
