# frozen_string_literal: true
# rubocop: disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class PopulateTestReportsIssueId
      def perform(start_id, stop_id)
        # NO OP
      end
    end
  end
end

Gitlab::BackgroundMigration::PopulateTestReportsIssueId.prepend_mod
