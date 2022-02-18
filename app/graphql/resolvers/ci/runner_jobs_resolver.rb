# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerJobsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include LooksAhead

      type ::Types::Ci::JobType.connection_type, null: true
      authorize :read_builds
      authorizes_object!

      argument :statuses, [::Types::Ci::JobStatusEnum],
               required: false,
               description: 'Filter jobs by status.'

      alias_method :runner, :object

      def ready?(**args)
        context[self.class] ||= { executions: 0 }
        context[self.class][:executions] += 1

        raise GraphQL::ExecutionError, "Jobs can be requested for only one runner at a time" if context[self.class][:executions] > 1

        super
      end

      def resolve_with_lookahead(statuses: nil)
        jobs = ::Ci::JobsFinder.new(current_user: current_user, runner: runner, params: { scope: statuses }).execute

        apply_lookahead(jobs)
      end

      private

      def preloads
        {
          previous_stage_jobs_and_needs: [:needs, :pipeline],
          artifacts: [:job_artifacts],
          pipeline: [:user]
        }
      end
    end
  end
end
