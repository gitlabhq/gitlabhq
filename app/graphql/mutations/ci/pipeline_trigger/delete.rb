# frozen_string_literal: true

module Mutations
  module Ci
    module PipelineTrigger
      class Delete < BaseMutation
        graphql_name 'PipelineTriggerDelete'

        authorize :manage_trigger

        argument :id, ::Types::GlobalIDType[::Ci::Trigger],
          required: true,
          description: 'ID of the pipeline trigger token to delete.'

        def resolve(id:)
          trigger = authorized_find!(id: id)
          response = ::Ci::PipelineTriggers::DestroyService.new(user: current_user, trigger: trigger).execute

          { errors: response.errors }
        end
      end
    end
  end
end
