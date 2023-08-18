# frozen_string_literal: true

module Mutations
  module Ci
    module PipelineTrigger
      class Base < BaseMutation
        authorize :admin_build
        authorize :admin_trigger

        PipelineTriggerID = ::Types::GlobalIDType[::Ci::Trigger]

        argument :id, PipelineTriggerID,
          required: true,
          description: 'ID of the pipeline trigger token to mutate.'
      end
    end
  end
end
