# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class StageType < BaseObject
      graphql_name 'CiStage'

      field :name, GraphQL::STRING_TYPE, null: true,
        description: 'Name of the stage.'
      field :groups, Ci::GroupType.connection_type, null: true,
        extras: [:lookahead],
        description: 'Group of jobs for the stage.'
      field :detailed_status, Types::Ci::DetailedStatusType, null: true,
        description: 'Detailed status of the stage.'
      field :jobs, Ci::JobType.connection_type, null: true,
        description: 'Jobs for the stage.',
        method: 'latest_statuses'

      def detailed_status
        object.detailed_status(current_user)
      end

      # Issues one query per pipeline
      def groups(lookahead:)
        key = ::Gitlab::Graphql::BatchKey.new(object, lookahead, object_name: :stage)

        BatchLoader::GraphQL.for(key).batch(default_value: []) do |keys, loader|
          by_pipeline = keys.group_by(&:pipeline)
          include_needs = keys.any? { |k| k.requires?(%i[nodes jobs nodes needs]) }

          by_pipeline.each do |pl, key_group|
            project = pl.project
            indexed = key_group.index_by(&:id)

            jobs_for_pipeline(pl, indexed.keys, include_needs).each do |stage_id, statuses|
              key = indexed[stage_id]
              groups = ::Ci::Group.fabricate(project, key.stage, statuses)

              if Feature.enabled?(:ci_no_empty_groups, project)
                groups.each do |group|
                  rejected = group.jobs.reject { |job| Ability.allowed?(current_user, :read_commit_status, job) }
                  group.jobs.select! { |job| Ability.allowed?(current_user, :read_commit_status, job) }
                  next unless group.jobs.empty?

                  exc = StandardError.new('Empty Ci::Group')
                  traces = rejected.map do |job|
                    trace = []
                    policy = Ability.policy_for(current_user, job)
                    policy.debug(:read_commit_status, trace)
                    trace
                  end
                  extra = {
                    current_user_id: current_user&.id,
                    project_id: project.id,
                    pipeline_id: pl.id,
                    stage_id: stage_id,
                    group_name: group.name,
                    rejected_job_ids: rejected.map(&:id),
                    rejected_traces: traces
                  }
                  Gitlab::ErrorTracking.track_exception(exc, extra)
                end
                groups.reject! { |group| group.jobs.empty? }
              end

              loader.call(key, groups)
            end
          end
        end
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def jobs_for_pipeline(pipeline, stage_ids, include_needs)
        results = pipeline.latest_statuses.where(stage_id: stage_ids)
        results = results.preload(:needs) if include_needs

        results.group_by(&:stage_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
