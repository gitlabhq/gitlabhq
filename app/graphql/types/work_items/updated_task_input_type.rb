# frozen_string_literal: true

module Types
  module WorkItems
    class UpdatedTaskInputType < BaseInputObject
      graphql_name 'WorkItemUpdatedTaskInput'

      include Mutations::WorkItems::UpdateArguments
    end
  end
end
