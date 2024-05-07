# frozen_string_literal: true

module Mutations
  module Ci
    module PipelineSchedule
      class Create < BaseMutation
        graphql_name 'PipelineScheduleCreate'

        include FindsProject

        authorize :create_pipeline_schedule

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Full path of the project the pipeline schedule is associated with.'

        argument :description, GraphQL::Types::String,
          required: true,
          description: 'Description of the pipeline schedule.'

        argument :cron, GraphQL::Types::String,
          required: true,
          description: 'Cron expression of the pipeline schedule.'

        argument :cron_timezone, GraphQL::Types::String,
          required: false,
          description:
          <<-STR
                    Cron time zone supported by ActiveSupport::TimeZone.
                    For example: "Pacific Time (US & Canada)" (default: "UTC").
          STR

        argument :ref, GraphQL::Types::String,
          required: true,
          description: 'Ref of the pipeline schedule.'

        argument :active, GraphQL::Types::Boolean,
          required: false,
          description: 'Indicates if the pipeline schedule should be active or not.'

        argument :variables, [Mutations::Ci::PipelineSchedule::VariableInputType],
          required: false,
          description: 'Variables for the pipeline schedule.'

        field :pipeline_schedule,
          Types::Ci::PipelineScheduleType,
          description: 'Created pipeline schedule.'

        def resolve(project_path:, variables: [], **pipeline_schedule_attrs)
          project = authorized_find!(project_path)

          params = pipeline_schedule_attrs.merge(variables_attributes: variables.map(&:to_h))

          response = ::Ci::PipelineSchedules::CreateService
                        .new(project, current_user, params)
                        .execute

          schedule = response.payload

          unless response.success?
            return {
              pipeline_schedule: nil, errors: response.errors
            }
          end

          {
            pipeline_schedule: schedule,
            errors: []
          }
        end
      end
    end
  end
end
