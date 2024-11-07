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

    alias_method :project, :object

    def resolve_with_lookahead(**args)
      jobs = ::Ci::JobsFinder.new(
        current_user: current_user, project: project, params: {
          scope: args[:statuses], with_artifacts: args[:with_artifacts]
        }
      ).execute

      if Feature.enabled?(:populate_and_use_build_names_table, project)
        jobs = ::Ci::BuildNameFinder.new(
          relation: jobs,
          name: args[:name],
          project: project,
          params: {
            before: decode_cursor(args[:before]), after: decode_cursor(args[:after]),
            asc: args[:last].present?, invert_ordering: true
          }
        ).execute
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
        pipeline: [:user]
      }
    end
  end
end
