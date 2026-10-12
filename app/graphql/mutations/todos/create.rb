# frozen_string_literal: true

module Mutations
  module Todos
    class Create < ::Mutations::BaseMutation
      graphql_name 'TodoCreate'

      authorize :create_todo
      authorize_granular_token permissions: :create_todo,
        boundaries: [
          { boundary_argument: :target_id, boundary: :resource_parent, boundary_type: :project },
          { boundary_argument: :target_id, boundary: :resource_parent, boundary_type: :group }
        ]

      argument :target_id,
        Types::GlobalIDType[Todoable],
        required: true,
        description: "Global ID of the to-do item's parent. Issues, " \
          "merge requests, designs, and epics are supported."

      argument :note_id,
        Types::GlobalIDType[Note],
        required: false,
        experiment: { milestone: '19.5' },
        description: 'Global ID of a comment on the target to associate with the to-do item. ' \
          'Ignored when the `todo_for_comment` feature flag is disabled.'

      field :todo, Types::TodoType,
        null: true,
        description: 'To-do item created.'

      def resolve(target_id:, note_id: nil)
        target = authorized_find!(id: target_id)
        note = find_note!(note_id, target) if note_id && Feature.enabled?(:todo_for_comment, current_user)

        todo = TodoService.new.mark_todo(target, current_user, note: note).first
        errors = errors_on_object(todo) if todo

        {
          todo: todo,
          errors: errors
        }
      end

      private

      def find_note!(note_id, target)
        note = GitlabSchema.find_by_gid(note_id).sync

        unless note && note_on_target?(note, target) && current_user.can?(:read_note, note)
          raise_resource_not_available_error!
        end

        note
      end

      # Matches on base_class so a WorkItem target accepts notes stored
      # against its underlying Issue.
      def note_on_target?(note, target)
        note.noteable_type == target.class.base_class.name && note.noteable_id == target.id
      end
    end
  end
end
