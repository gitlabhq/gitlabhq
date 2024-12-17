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
      experiment: { milestone: '17.1' },
      description: 'Filter jobs by name.'

    argument :sources, [::Types::Ci::JobSourceEnum],
      required: false,
      experiment: { milestone: '17.7' },
      description: "Filter jobs by source. Ignored if " \
        "'populate_and_use_build_source_table' feature flag is disabled."

    alias_method :project, :object

    def resolve_with_lookahead(**args)
      filter_by_name = Feature.enabled?(:populate_and_use_build_names_table, project) && args[:name].to_s.present?
      filter_by_sources = Feature.enabled?(:populate_and_use_build_source_table, project) && args[:sources].present?

      jobs = ::Ci::JobsFinder.new(
        current_user: current_user, project: project, params: {
          scope: args[:statuses], with_artifacts: args[:with_artifacts],
          skip_ordering: filter_by_sources
        }
      ).execute

      # These job filters are currently exclusive with each other
      if filter_by_name
        jobs = ::Ci::BuildNameFinder.new(
          relation: jobs,
          name: args[:name],
          project: project,
          params: {
            before: decode_cursor(args[:before]), after: decode_cursor(args[:after]),
            asc: args[:last].present?, invert_ordering: true
          }
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

    def decode_cursor(encoded)
      return unless encoded.present?

      Gitlab::Json.parse(context.schema.cursor_encoder.decode(encoded, nonce: true))&.fetch('id')
    rescue JSON::ParserError
      raise Gitlab::Graphql::Errors::ArgumentError, "Please provide a valid cursor"
    end

    def preloads
      {
        previous_stage_jobs_or_needs: [:needs, :pipeline],
        artifacts: [:job_artifacts],
        pipeline: [:user],
        build_source: [:source]
      }
    end
  end
end
