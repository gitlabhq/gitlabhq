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
      operation_name :delete_invalid_todos
      feature_category :database

      def perform
        # no-op: this BG migration is left here only for compatibility reasons,
        # but it's not scheduled from any migration anymore.
        # It was a temporary migration which used not-isolated code.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/382557
      end
    end
  end
end
