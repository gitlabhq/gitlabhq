# frozen_string_literal: true

module Types
  module Ci
    class PipelineScheduleType < BaseObject
      graphql_name 'PipelineSchedule'

      description 'Represents a pipeline schedule'

      connection_type_class Types::CountableConnectionType

      expose_permissions Types::PermissionTypes::Ci::PipelineSchedules

      authorize :read_pipeline_schedule

      field :id, GraphQL::Types::ID, null: false, description: 'ID of the pipeline schedule.'

      field :description, GraphQL::Types::String, null: true, description: 'Description of the pipeline schedule.'

      field :owner, ::Types::UserType, null: true, description: 'Owner of the pipeline schedule.'

      field :active, GraphQL::Types::Boolean, null: false, description: 'Indicates if the pipeline schedule is active.'

      field :project, ::Types::ProjectType, null: true, description: 'Project of the pipeline schedule.'

      field :next_run_at, Types::TimeType, null: true, description: 'Time when the next pipeline will run.'

      field :real_next_run, Types::TimeType, null: true, description: 'Time when the next pipeline will run.'

      field :last_pipeline, PipelineType, null: true, description: 'Last pipeline object.'

      field :ref_for_display, GraphQL::Types::String,
        null: true, description: 'Git ref for the pipeline schedule.'

      field :for_tag, GraphQL::Types::Boolean,
        null: false, description: 'Indicates if a pipelines schedule belongs to a tag.', method: :for_tag?

      field :edit_path, GraphQL::Types::String,
        null: true,
        description: 'Edit path of the pipeline schedule.',
        authorize: :update_pipeline_schedule

      field :variables,
        Types::Ci::PipelineScheduleVariableType.connection_type,
        null: true,
        description: 'Pipeline schedule variables.',
        authorize: :read_pipeline_schedule_variables

      field :ref, GraphQL::Types::String,
        null: true, description: 'Ref of the pipeline schedule.', method: :ref_for_display

      field :ref_path, GraphQL::Types::String,
        null: true,
        description: 'Path to the ref that triggered the pipeline.'

      field :cron, GraphQL::Types::String,
        null: false,
        description: 'Cron notation for the schedule.'

      field :cron_timezone, GraphQL::Types::String,
        null: false,
        description: 'Timezone for the pipeline schedule.'

      field :created_at, Types::TimeType,
        null: false, description: 'Timestamp of when the pipeline schedule was created.'

      field :updated_at, Types::TimeType,
        null: false, description: 'Timestamp of when the pipeline schedule was last updated.'

      def ref_path
        ref_for_display = object.ref_for_display
        return unless ref_for_display

        ::Gitlab::Routing.url_helpers.project_commits_path(object.project, ref_for_display)
      end

      def edit_path
        ::Gitlab::Routing.url_helpers.edit_project_pipeline_schedule_path(object.project, object)
      end
    end
  end
end
