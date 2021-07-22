# frozen_string_literal: true

module Resolvers
  class TodoResolver < BaseResolver
    type Types::TodoType.connection_type, null: true

    alias_method :target, :object

    argument :action, [Types::TodoActionEnum],
             required: false,
             description: 'The action to be filtered.'

    argument :author_id, [GraphQL::Types::ID],
             required: false,
             description: 'The ID of an author.'

    argument :project_id, [GraphQL::Types::ID],
             required: false,
             description: 'The ID of a project.'

    argument :group_id, [GraphQL::Types::ID],
             required: false,
             description: 'The ID of a group.'

    argument :state, [Types::TodoStateEnum],
             required: false,
             description: 'The state of the todo.'

    argument :type, [Types::TodoTargetEnum],
             required: false,
             description: 'The type of the todo.'

    def resolve(**args)
      return Todo.none unless current_user.present? && target.present?
      return Todo.none if target.is_a?(User) && target != current_user

      TodosFinder.new(current_user, todo_finder_params(args)).execute
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
      }.merge(target_params)
    end

    def target_params
      return {} unless TodosFinder::TODO_TYPES.include?(target.class.name)

      {
        type: target.class.name,
        target_id: target.id
      }
    end
  end
end
