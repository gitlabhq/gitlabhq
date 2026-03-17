# frozen_string_literal: true

module Ci
  class PipelineCreationMetricsWorker
    include ApplicationWorker
    include PipelineBackgroundQueue
    include Gitlab::InternalEventsTracking

    data_consistency :delayed
    urgency :low
    feature_category :continuous_integration
    defer_on_database_health_signal :gitlab_ci, [:p_ci_builds, :ci_pipelines], 1.minute
    idempotent!

    def perform(pipeline_id, inputs_count = nil, template_names = nil, keyword_usage = nil)
      pipeline = Ci::Pipeline.find_by_id(pipeline_id)
      return unless pipeline

      increment_pipeline_created_counter(pipeline)
      create_snowplow_event_for_pipeline_name(pipeline)
      track_inputs_usage(pipeline, inputs_count)
      track_template_usage(pipeline, template_names)
      track_keyword_usage_events(pipeline, keyword_usage)
      track_build_creation(pipeline)
    end

    private

    def increment_pipeline_created_counter(pipeline)
      labels = {
        source: pipeline.source,
        partition_id: pipeline.partition_id
      }

      ::Gitlab::Ci::Pipeline::Metrics
        .pipelines_created_counter
        .increment(**labels)
    end

    def create_snowplow_event_for_pipeline_name(pipeline)
      return unless pipeline.pipeline_metadata&.name

      Gitlab::Tracking.event(
        'Gitlab::Ci::Pipeline::Chain::Metrics',
        'create_pipeline_with_name',
        project: pipeline.project,
        user: pipeline.user,
        namespace: pipeline.project.namespace
      )
    end

    def track_inputs_usage(pipeline, inputs_count)
      return unless inputs_count.to_i > 0

      track_internal_event(
        'create_pipeline_with_inputs',
        project: pipeline.project,
        user: pipeline.user,
        additional_properties: {
          label: pipeline.source,
          property: pipeline.config_source,
          value: inputs_count
        }
      )
    end

    def track_template_usage(pipeline, template_names)
      return if template_names.blank?

      template_names.each do |template|
        Gitlab::UsageDataCounters::CiTemplateUniqueCounter
          .track_unique_project_event(
            project: pipeline.project,
            template: template,
            config_source: pipeline.config_source,
            user: pipeline.user
          )
      end
    end

    def track_keyword_usage_events(pipeline, keyword_usage)
      return if keyword_usage.blank?

      keyword_usage.each do |keyword, used|
        next unless used

        Gitlab::InternalEvents.track_event(
          "use_#{keyword}_keyword_in_cicd_yaml",
          project: pipeline.project,
          user: pipeline.user
        )
      end
    end

    def track_build_creation(pipeline)
      preloaded_builds = pipeline.builds.includes(:user, :job_definition, namespace: :route, project: :namespace) # rubocop:disable CodeReuse/ActiveRecord -- Preload to prevent N+1 queries when tracking events

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
