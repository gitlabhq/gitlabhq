# frozen_string_literal: true

module Types
  module Ci
    class StageType < BaseObject
      graphql_name 'CiStage'
      authorize :read_build

      field :detailed_status, Types::Ci::DetailedStatusType, null: true,
        description: 'Detailed status of the stage.'
      field :groups, type: Ci::GroupType.connection_type, null: true,
        extras: [:lookahead],
        description: 'Group of jobs for the stage.'
      field :id, GraphQL::Types::ID, null: false,
        description: 'ID of the stage.'
      field :jobs, Types::Ci::JobType.connection_type, null: true,
        description: 'Jobs for the stage.'
      field :name, type: GraphQL::Types::String, null: true,
        description: 'Name of the stage.'
      field :status, GraphQL::Types::String,
        null: true,
        description: 'Status of the pipeline stage.'

      def detailed_status
        object.detailed_status(current_user)
      end

      # Issues one query per pipeline
      def groups(lookahead:)
        key = ::Gitlab::Graphql::BatchKey.new(object, lookahead, object_name: :stage)

        BatchLoader::GraphQL.for(key).batch(default_value: []) do |keys, loader|
          by_pipeline = keys.group_by(&:pipeline)
          include_needs = keys.any? do |k|
            k.requires?(%i[nodes jobs nodes needs]) ||
              k.requires?(%i[nodes jobs nodes previousStageJobsOrNeeds])
          end

          by_pipeline.each do |pl, key_group|
            project = pl.project
            indexed = key_group.index_by(&:id)

            jobs_for_pipeline(pl, indexed.keys, include_needs).each do |stage_id, statuses|
              key = indexed[stage_id]
              groups = ::Ci::Group.fabricate(project, key.stage, statuses)

              loader.call(key, groups)
            end
          end
        end
      end

      def jobs
        GraphQL::Pagination::ActiveRecordRelationConnection.new(
          object.ordered_latest_statuses,
          max_page_size: Gitlab::CurrentSettings.current_application_settings.jobs_per_stage_page_size
        )
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def jobs_for_pipeline(pipeline, stage_ids, include_needs)
        jobs = pipeline.statuses.latest.where(stage_id: stage_ids)

        preloaded_relations = [:project, :metadata, :job_artifacts, :downstream_pipeline]
        preloaded_relations << :needs if include_needs

        Preloaders::CommitStatusPreloader.new(jobs).execute(preloaded_relations)

        jobs.group_by(&:stage_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
