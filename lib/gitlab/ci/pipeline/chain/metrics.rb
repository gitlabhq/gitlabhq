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
            track_build_creation
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

          def track_build_creation
            preloaded_builds = @pipeline.builds.includes(:user, :job_definition, namespace: :route, project: :namespace) # rubocop:disable CodeReuse/ActiveRecord -- Preload to prevent N+1 queries when tracking events

            preloaded_builds.each do |build|
              track_build_created_event(build)
            end

            track_id_tokens_usage_batch(preloaded_builds.select(&:id_tokens?))
          end

          def track_build_created_event(build)
            Gitlab::InternalEvents.track_event(
              'create_ci_build',
              project: build.project,
              user: build.user,
              property: build.name
            )
          end

          def track_id_tokens_usage_batch(builds_with_tokens)
            return if builds_with_tokens.empty?

            user_ids = builds_with_tokens.filter_map(&:user_id).uniq

            ::Gitlab::UsageDataCounters::HLLRedisCounter.track_event(
              'i_ci_secrets_management_id_tokens_build_created',
              values: user_ids
            )

            builds_with_tokens.each do |build|
              Gitlab::Tracking.event(
                build.class.to_s,
                'create_id_tokens',
                namespace: build.namespace,
                user: build.user,
                label: 'redis_hll_counters.ci_secrets_management.' \
                  'i_ci_secrets_management_id_tokens_build_created_monthly',
                ultimate_namespace_id: build.namespace.traversal_ids.first,
                context: [Gitlab::Tracking::ServicePingContext.new(
                  data_source: :redis_hll,
                  event: 'i_ci_secrets_management_id_tokens_build_created'
                ).to_context]
              )
            end
          end
        end
      end
    end
  end
end
