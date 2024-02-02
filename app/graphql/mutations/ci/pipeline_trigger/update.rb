# frozen_string_literal: true

module Mutations
  module Ci
    module PipelineTrigger
      class Update < BaseMutation
        graphql_name 'PipelineTriggerUpdate'

        authorize :admin_trigger

        argument :id, ::Types::GlobalIDType[::Ci::Trigger],
          required: true,
          description: 'ID of the pipeline trigger token to update.'

        argument :description, GraphQL::Types::String,
          required: true,
          description: 'Description of the pipeline trigger token.'

        field :pipeline_trigger, Types::Ci::PipelineTriggerType,
          null: true,
          description: 'Mutated pipeline trigger token.'

        def resolve(id:, description:)
          trigger = authorized_find!(id: id)

          response = ::Ci::PipelineTriggers::UpdateService.new(user: current_user, trigger: trigger,
            description: description).execute

          {
            pipeline_trigger: response.payload[:trigger],
            errors: response.errors
          }
        end
      end
    end
  end
end
