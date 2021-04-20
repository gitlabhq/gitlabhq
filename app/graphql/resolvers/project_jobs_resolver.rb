# frozen_string_literal: true

module Resolvers
  class ProjectJobsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include LooksAhead

    type ::Types::Ci::JobType.connection_type, null: true
    authorize :read_build
    authorizes_object!

    argument :statuses, [::Types::Ci::JobStatusEnum],
              required: false,
              description: 'Filter jobs by status.'

    alias_method :project, :object

    def ready?(**args)
      context[self.class] ||= { executions: 0 }
      context[self.class][:executions] += 1
      raise GraphQL::ExecutionError, "Jobs can only be requested for one project at a time" if context[self.class][:executions] > 1

      super
    end

    def resolve_with_lookahead(statuses: nil)
      jobs = ::Ci::JobsFinder.new(current_user: current_user, project: project, params: { scope: statuses }).execute

      apply_lookahead(jobs)
    end

    private

    def preloads
      {
        artifacts: [:job_artifacts],
        pipeline: [:user]
      }
    end
  end
end
