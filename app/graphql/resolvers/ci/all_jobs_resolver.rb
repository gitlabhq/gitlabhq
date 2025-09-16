# frozen_string_literal: true

module Resolvers
  module Ci
    class AllJobsResolver < BaseResolver
      include LooksAhead

      COMPATIBLE_RUNNER_ERROR_MESSAGE =
        'compatibleRunnerId can only be used when the `statuses` argument is set to "PENDING"'

      type ::Types::Ci::JobInterface.connection_type, null: true

      argument :statuses, [::Types::Ci::JobStatusEnum],
        required: false,
        description: 'Filter jobs by status.'

      argument :runner_types, [::Types::Ci::RunnerTypeEnum],
        required: false,
        experiment: { milestone: '16.4' },
        description: 'Filter jobs by runner type if ' \
          'feature flag `:admin_jobs_filter_runner_type` is enabled.'

      argument :compatible_runner_id, ::Types::GlobalIDType[::Ci::Runner],
        required: false,
        experiment: { milestone: '18.1' },
        description: 'ID of a runner that matches the requirements of the jobs returned ' \
          '(normally used when filtering pending jobs).'

      def ready?(**args)
        if args.key?(:compatible_runner_id) && args[:statuses] != %w[pending]
          raise Gitlab::Graphql::Errors::ArgumentError, COMPATIBLE_RUNNER_ERROR_MESSAGE
        end

        super
      end

      def resolve_with_lookahead(**args)
        jobs = ::Ci::JobsFinder.new(current_user: current_user, **runner_args(args), params: params_data(args)).execute

        apply_lookahead(jobs)
      end

      private

      def params_data(args)
        {
          scope: args[:statuses],
          runner_type: args[:runner_types],
          match_compatible_runner_only: args[:compatible_runner_id].present?
        }
      end

      def runner_args(args)
        return {} unless args.key?(:compatible_runner_id)

        { runner: GitlabSchema.object_from_id(args[:compatible_runner_id], expected_type: ::Ci::Runner).sync }
      end

      def preloads
        {
          previous_stage_jobs_or_needs: [:needs, :pipeline],
          artifacts: [:job_artifacts],
          pipeline: [:user],
          kind: [:metadata, :job_definition, :error_job_messages],
          retryable: [:metadata, :job_definition, :error_job_messages],
          project: [{ project: [:route, { namespace: [:route] }] }],
          commit_path: [:pipeline, { project: { namespace: [:route] } }],
          ref_path: [{ project: [:route, { namespace: [:route] }] }],
          browse_artifacts_path: [{ project: { namespace: [:route] } }],
          play_path: [{ project: { namespace: [:route] } }],
          web_path: [{ project: { namespace: [:route] } }],
          tags: [:tags],
          trace: [{ project: [:namespace] }, :job_artifacts_trace],
          source: [:build_source]
        }
      end

      def nested_preloads
        super.merge({
          trace: {
            html_summary: [:trace_chunks]
          }
        })
      end

      # Overridden in EE
      def unconditional_includes
        []
      end
    end
  end
end

Resolvers::Ci::AllJobsResolver.prepend_mod
