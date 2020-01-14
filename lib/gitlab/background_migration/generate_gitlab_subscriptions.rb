# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class GenerateGitlabSubscriptions
      def perform(start_id, stop_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::GenerateGitlabSubscriptions.prepend_if_ee('EE::Gitlab::BackgroundMigration::GenerateGitlabSubscriptions')
