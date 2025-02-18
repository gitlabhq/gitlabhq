# frozen_string_literal: true

module Mutations
  module Ci
    module PipelineTrigger
      class Create < BaseMutation
        graphql_name 'PipelineTriggerCreate'

        include FindsProject

        authorize :manage_trigger

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Full path of the project that the pipeline trigger token to mutate is in.'

        argument :description, GraphQL::Types::String,
          required: true,
          description: 'Description of the pipeline trigger token.'

        argument :expires_at, Types::TimeType,
          required: false,
          description: 'Timestamp of when the pipeline trigger token expires.'

        field :pipeline_trigger, Types::Ci::PipelineTriggerType,
          null: true,
          description: 'Mutated pipeline trigger token.'

        def resolve(project_path:, description:, expires_at: nil)
          project = authorized_find!(project_path)

          response = ::Ci::PipelineTriggers::CreateService.new(project: project, user: current_user,
            description: description, expires_at: expires_at).execute

          trigger = response.payload[:trigger]

          {
            pipeline_trigger: trigger,
            errors: trigger.errors.full_messages
          }
        end
      end
    end
  end
end
