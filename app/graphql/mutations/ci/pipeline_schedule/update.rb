# frozen_string_literal: true

module Mutations
  module Ci
    module PipelineSchedule
      class Update < Base
        graphql_name 'PipelineScheduleUpdate'

        authorize :update_pipeline_schedule

        argument :description, GraphQL::Types::String,
          required: false,
          description: 'Description of the pipeline schedule.'

        argument :cron, GraphQL::Types::String,
          required: false,
          description: 'Cron expression of the pipeline schedule.'

        argument :cron_timezone, GraphQL::Types::String,
          required: false,
          description:
          <<-STR
                    Cron time zone supported by ActiveSupport::TimeZone.
                    For example: "Pacific Time (US & Canada)" (default: "UTC").
          STR

        argument :ref, GraphQL::Types::String,
          required: false,
          description: 'Ref of the pipeline schedule.'

        argument :active, GraphQL::Types::Boolean,
          required: false,
          description: 'Indicates if the pipeline schedule should be active or not.'

        argument :variables, [Mutations::Ci::PipelineSchedule::VariableInputType],
          required: false,
          description: 'Variables for the pipeline schedule.'

        field :pipeline_schedule,
          Types::Ci::PipelineScheduleType,
          description: 'Updated pipeline schedule.'

        def resolve(id:, variables: [], **pipeline_schedule_attrs)
          schedule = authorized_find!(id: id)

          params = pipeline_schedule_attrs.merge(variables_attributes: variable_attributes_for(variables))

          service_response = ::Ci::PipelineSchedules::UpdateService
            .new(schedule, current_user, params)
            .execute

          {
            pipeline_schedule: schedule,
            errors: service_response.errors
          }
        end

        private

        def variable_attributes_for(variables)
          variables.map do |variable|
            variable.to_h.tap do |hash|
              hash[:id] = GlobalID::Locator.locate(hash[:id]).id if hash[:id]

              hash[:_destroy] = hash.delete(:destroy)
            end
          end
        end
      end
    end
  end
end
