# frozen_string_literal: true

module Resolvers
  class ProjectJobsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include LooksAhead

    type ::Types::Ci::JobType.connection_type, null: true
    authorize :read_build
    authorizes_object!
    extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1

    argument :statuses, [::Types::Ci::JobStatusEnum],
              required: false,
              description: 'Filter jobs by status.'

    argument :with_artifacts, ::GraphQL::Types::Boolean,
              required: false,
              description: 'Filter by artifacts presence.'

    alias_method :project, :object

    def resolve_with_lookahead(statuses: nil, with_artifacts: nil)
      jobs = ::Ci::JobsFinder.new(
        current_user: current_user, project: project, params: {
          scope: statuses, with_artifacts: with_artifacts
        }
      ).execute

      apply_lookahead(jobs)
    end

    private

    def preloads
      {
        previous_stage_jobs_or_needs: [:needs, :pipeline],
        artifacts: [:job_artifacts],
        pipeline: [:user]
      }
    end
  end
end
