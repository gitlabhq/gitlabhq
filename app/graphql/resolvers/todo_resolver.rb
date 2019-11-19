# frozen_string_literal: true

module Resolvers
  class TodoResolver < BaseResolver
    type Types::TodoType, null: true

    alias_method :user, :object

    argument :action, [Types::TodoActionEnum],
             required: false,
             description: 'The action to be filtered'

    argument :author_id, [GraphQL::ID_TYPE],
             required: false,
             description: 'The ID of an author'

    argument :project_id, [GraphQL::ID_TYPE],
             required: false,
             description: 'The ID of a project'

    argument :group_id, [GraphQL::ID_TYPE],
             required: false,
             description: 'The ID of a group'

    argument :state, [Types::TodoStateEnum],
             required: false,
             description: 'The state of the todo'

    argument :type, [Types::TodoTargetEnum],
             required: false,
             description: 'The type of the todo'

    def resolve(**args)
      return Todo.none if user != context[:current_user]

      TodosFinder.new(user, todo_finder_params(args)).execute
    end

    private

    def todo_finder_params(args)
      {
        state: args[:state],
        type: args[:type],
        group_id: args[:group_id],
        author_id: args[:author_id],
        action_id: args[:action],
        project_id: args[:project_id]
      }
    end
  end
end
