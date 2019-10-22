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

    # TODO: Support multiple queries for e.g. state and type on TodosFinder:
    #
    # https://gitlab.com/gitlab-org/gitlab/merge_requests/18487
    # https://gitlab.com/gitlab-org/gitlab/merge_requests/18518
    #
    # As soon as these MR's are merged, we can refactor this to query by
    # multiple contents.
    #
    def todo_finder_params(args)
      {
        state: first_state(args),
        type: first_type(args),
        group_id: first_group_id(args),
        author_id: first_author_id(args),
        action_id: first_action(args),
        project_id: first_project(args)
      }
    end

    def first_project(args)
      first_query_field(args, :project_id)
    end

    def first_action(args)
      first_query_field(args, :action)
    end

    def first_author_id(args)
      first_query_field(args, :author_id)
    end

    def first_group_id(args)
      first_query_field(args, :group_id)
    end

    def first_state(args)
      first_query_field(args, :state)
    end

    def first_type(args)
      first_query_field(args, :type)
    end

    def first_query_field(query, field)
      return unless query.key?(field)

      query[field].first if query[field].respond_to?(:first)
    end
  end
end
