# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class BackfillVersionDataFromGitaly
      def perform(issue_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::BackfillVersionDataFromGitaly.prepend_if_ee('EE::Gitlab::BackgroundMigration::BackfillVersionDataFromGitaly')
