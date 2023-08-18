# frozen_string_literal: true

module Mutations
  module Ci
    module PipelineTrigger
      class Delete < Base
        graphql_name 'PipelineTriggerDelete'

        def resolve(id:)
          trigger = authorized_find!(id: id)

          errors = trigger.destroy ? [] : ['Could not remove the trigger']

          { errors: errors }
        end
      end
    end
  end
end
