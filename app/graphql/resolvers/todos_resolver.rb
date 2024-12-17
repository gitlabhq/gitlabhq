# frozen_string_literal: true

module Resolvers
  class TodosResolver < BaseResolver
    type Types::TodoType.connection_type, null: true

    alias_method :target, :object

    argument :action, [Types::TodoActionEnum],
      required: false,
      description: 'Action to be filtered.'

    argument :author_id, [GraphQL::Types::ID],
      required: false,
      description: 'ID of an author.'

    argument :project_id, [GraphQL::Types::ID],
      required: false,
      description: 'ID of a project.'

    argument :group_id, [GraphQL::Types::ID],
      required: false,
      description: 'ID of a group.'

    argument :state, [Types::TodoStateEnum],
      required: false,
      description: 'State of the todo.'

    argument :is_snoozed, GraphQL::Types::Boolean,
      required: false,
      description: 'Whether the to-do item is snoozed.'

    argument :type, [Types::TodoTargetEnum],
      required: false,
      description: 'Type of the todo.'

    argument :sort, Types::TodoSortEnum,
      required: false,
      description: 'Sort todos by given criteria.'

    before_connection_authorization do |nodes, current_user|
      Preloaders::UserMaxAccessLevelInProjectsPreloader.new(
        nodes.map(&:project).compact,
        current_user
      ).execute
    end

    def resolve(**args)
      return Todo.none unless current_user.present? && target.present?
      return Todo.none if target.is_a?(User) && target != current_user

      TodosFinder.new(current_user, todo_finder_params(args)).execute.with_entity_associations
    end

    private

    def todo_finder_params(args)
      {
        state: args[:state],
        is_snoozed: args[:is_snoozed],
        type: args[:type],
        group_id: args[:group_id],
        author_id: args[:author_id],
        action_id: args[:action],
        project_id: args[:project_id],
        sort: args[:sort]
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
