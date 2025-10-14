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

    argument :name, GraphQL::Types::String,
      required: false,
      experiment: { milestone: '17.11' },
      description: 'Filter jobs by name.'

    argument :sources, [::Types::Ci::JobSourceEnum],
      required: false,
      experiment: { milestone: '17.7' },
      description: "Filter jobs by source."

    argument :kind, ::Types::Ci::JobKindEnum,
      required: false,
      description: 'Filter jobs by kind.'

    alias_method :project, :object

    def resolve_with_lookahead(**args)
      @kind = args[:kind]
      @with_artifacts = args[:with_artifacts]

      filter_by_name = args[:name].to_s.present?
      filter_by_sources = args[:sources].present?

      jobs = ::Ci::JobsFinder.new(
        current_user: current_user, project: project, params: {
          scope: args[:statuses], with_artifacts: args[:with_artifacts],
          skip_ordering: filter_by_sources
        }, type: args[:kind] || ::Ci::Build
      ).execute

      # These job filters are currently exclusive with each other
      if filter_by_name
        jobs = ::Ci::BuildNameFinder.new(
          relation: jobs,
          name: args[:name],
          project: project
        ).execute
      elsif filter_by_sources
        jobs = ::Ci::BuildSourceFinder.new(
          relation: jobs,
          sources: args[:sources],
          project: project
        ).execute

        return offset_pagination(apply_lookahead(jobs))
      end

      apply_lookahead(jobs)
    end

    private

    def should_preload_artifacts?
      @with_artifacts || @kind == ::Ci::Build
    end

    def preloads
      base_preloads = {
        previous_stage_jobs_or_needs: [:needs, :pipeline],
        pipeline: [:user],
        build_source: [:source]
      }

      base_preloads[:artifacts] = [:job_artifacts] if should_preload_artifacts?

      base_preloads
    end
  end
end
