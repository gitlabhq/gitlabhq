# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class StageType < BaseObject
      graphql_name 'CiStage'

      field :name, GraphQL::STRING_TYPE, null: true,
        description: 'Name of the stage'
      field :groups, Ci::GroupType.connection_type, null: true,
        description: 'Group of jobs for the stage'
      field :detailed_status, Types::Ci::DetailedStatusType, null: true,
            description: 'Detailed status of the stage'

      def detailed_status
        object.detailed_status(context[:current_user])
      end

      # Issues one query per pipeline
      def groups
        BatchLoader::GraphQL.for([object.pipeline, object]).batch(default_value: []) do |keys, loader|
          by_pipeline = keys.group_by(&:first)

          by_pipeline.each do |pl, key_group|
            project = pl.project
            stages = key_group.map(&:second).uniq
            indexed = stages.index_by(&:id)
            results = pl.latest_statuses.where(stage_id: stages.map(&:id)) # rubocop: disable CodeReuse/ActiveRecord

            results.group_by(&:stage_id).each do |stage_id, statuses|
              stage = indexed[stage_id]
              groups = ::Ci::Group.fabricate(project, stage, statuses)
              loader.call([pl, stage], groups)
            end
          end
        end
      end
    end
  end
end
