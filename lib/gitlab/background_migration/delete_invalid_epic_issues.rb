# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class DeleteInvalidEpicIssues
      def perform(start_id, stop_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::DeleteInvalidEpicIssues.prepend_mod_with('Gitlab::BackgroundMigration::DeleteInvalidEpicIssues')
