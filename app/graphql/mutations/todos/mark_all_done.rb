# frozen_string_literal: true

module Mutations
  module Todos
    class MarkAllDone < ::Mutations::BaseMutation
      graphql_name 'TodosMarkAllDone'

      authorize :update_user

      TodoableID = Types::GlobalIDType[Todoable]

      argument :target_id,
        TodoableID,
        required: false,
        description: "Global ID of the to-do item's parent. Issues, merge requests, designs, and epics are supported. " \
          "If argument is omitted, all pending to-do items of the current user are marked as done."

      argument :author_id, [GraphQL::Types::ID],
        required: false,
        description: 'ID of an author.'

      argument :project_id, [GraphQL::Types::ID],
        required: false,
        description: 'ID of a project.'

      argument :group_id, [GraphQL::Types::ID],
        required: false,
        description: 'ID of a group.'

      argument :action, [Types::TodoActionEnum],
        required: false,
        description: 'Action to be filtered.'

      argument :type, [Types::TodoTargetEnum],
        required: false,
        description: 'Type of the todo.'

      field :todos, [::Types::TodoType],
        null: false,
        description: 'Updated to-do items.'

      def resolve(**args)
        authorize!(current_user)

        updated_ids = mark_all_todos_done(**args)

        {
          todos: Todo.id_in(updated_ids),
          errors: []
        }
      end

      private

      def mark_all_todos_done(**args)
        return [] unless current_user

        finder_params = todo_finder_params(args)

        if args[:target_id].present?
          target = Gitlab::Graphql::Lazy.force(
            GitlabSchema.find_by_gid(args[:target_id])
          )

          if target.nil?
            raise Gitlab::Graphql::Errors::ResourceNotAvailable, "Resource not available: #{args[:target_id]}"
          end

          finder_params[:type] = target.class.name
          finder_params[:target_id] = target.id
        end

        todos = TodosFinder.new(current_user, finder_params).execute

        TodoService.new.resolve_todos(todos, current_user, resolved_by_action: :api_all_done)
      end

      def todo_finder_params(args)
        {
          state: :pending,
          type: args[:type],
          group_id: args[:group_id],
          author_id: args[:author_id],
          action_id: args[:action],
          project_id: args[:project_id]
        }
      end
    end
  end
end
