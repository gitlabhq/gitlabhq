# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Iterates through confidential notes and removes any its todos if user can
    # not read the note
    #
    # Warning: This migration is not properly isolated. The reason for this is
    # that we need to check permission for notes and it would be difficult
    # to extract all related logic.
    # Details in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87908#note_952459215
    class SanitizeConfidentialTodos < BatchedMigrationJob
      scope_to ->(relation) { relation.where(confidential: true) }

      operation_name :delete_invalid_todos
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          delete_ids = invalid_todo_ids(sub_batch)

          Todo.where(id: delete_ids).delete_all if delete_ids.present?
        end
      end

      private

      def invalid_todo_ids(notes_batch)
        todos = Todo.where(note_id: notes_batch.select(:id)).includes(:note, :user)

        todos.each_with_object([]) do |todo, ids|
          ids << todo.id if invalid_todo?(todo)
        end
      end

      def invalid_todo?(todo)
        return false unless todo.note
        return false if Ability.allowed?(todo.user, :read_todo, todo)

        logger.info(
          message: "#{self.class.name} deleting invalid todo",
          attributes: todo.attributes
        )

        true
      end

      def logger
        @logger ||= Gitlab::BackgroundMigration::Logger.build
      end
    end
  end
end
