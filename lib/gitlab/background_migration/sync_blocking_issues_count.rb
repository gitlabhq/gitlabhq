# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class SyncBlockingIssuesCount
      def perform(start_id, end_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::SyncBlockingIssuesCount.prepend_if_ee('EE::Gitlab::BackgroundMigration::SyncBlockingIssuesCount')
