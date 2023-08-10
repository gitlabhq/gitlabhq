# frozen_string_literal: true

module Mutations
  module Ci
    module PipelineTrigger
      class Create < BaseMutation
        graphql_name 'PipelineTriggerCreate'

        include FindsProject

        authorize :admin_build

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Full path of the project that the pipeline trigger token to mutate is in.'

        argument :description, GraphQL::Types::String,
          required: true,
          description: 'Description of the pipeline trigger token.'

        field :pipeline_trigger, Types::Ci::PipelineTriggerType,
          null: true,
          description: 'Mutated pipeline trigger token.'

        def resolve(project_path:, description:)
          project = authorized_find!(project_path)

          trigger = project.triggers.create(owner: current_user, description: description)

          {
            pipeline_trigger: trigger,
            errors: trigger.errors.full_messages
          }
        end
      end
    end
  end
end
