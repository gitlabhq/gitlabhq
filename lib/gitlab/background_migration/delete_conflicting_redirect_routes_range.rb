# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class DeleteConflictingRedirectRoutesRange
      def perform(start_id, end_id)
        # No-op.
        # See https://gitlab.com/gitlab-com/infrastructure/issues/3460#note_53223252
      end
    end
  end
end
