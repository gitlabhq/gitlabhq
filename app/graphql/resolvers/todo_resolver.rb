# frozen_string_literal: true

module Resolvers
  class TodoResolver < BaseResolver
    description 'Retrieve a single to-do item'

    type Types::TodoType, null: true

    argument :id, Types::GlobalIDType[Todo],
      required: true,
      description: 'ID of the to-do item.'

    def resolve(id:)
      GitlabSchema.find_by_gid(id)
    end
  end
end
