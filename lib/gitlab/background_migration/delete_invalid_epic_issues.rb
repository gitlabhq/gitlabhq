# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class DeleteInvalidEpicIssues < BatchedMigrationJob
      feature_category :database

      def perform
      end
    end
  end
end

# rubocop:disable Layout/LineLength
Gitlab::BackgroundMigration::DeleteInvalidEpicIssues.prepend_mod_with('Gitlab::BackgroundMigration::DeleteInvalidEpicIssues')
