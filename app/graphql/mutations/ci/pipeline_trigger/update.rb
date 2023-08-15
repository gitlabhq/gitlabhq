# frozen_string_literal: true

module Mutations
  module Ci
    module PipelineTrigger
      class Update < Base
        graphql_name 'PipelineTriggerUpdate'

        argument :description, GraphQL::Types::String,
          required: true,
          description: 'Description of the pipeline trigger token.'

        field :pipeline_trigger, Types::Ci::PipelineTriggerType,
          null: true,
          description: 'Mutated pipeline trigger token.'

        def resolve(id:, description:)
          trigger = authorized_find!(id: id)

          trigger.description = description

          trigger.save

          {
            pipeline_trigger: trigger,
            errors: trigger.errors.full_messages
          }
        end
      end
    end
  end
end
