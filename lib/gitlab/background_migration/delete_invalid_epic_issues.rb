# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteInvalidEpicIssues < BatchedMigrationJob
      feature_category :database

      def perform; end
    end
  end
end

# rubocop:disable Layout/LineLength
Gitlab::BackgroundMigration::DeleteInvalidEpicIssues.prepend_mod_with('Gitlab::BackgroundMigration::DeleteInvalidEpicIssues')
