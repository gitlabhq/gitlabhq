# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class UpdateVulnerabilitiesFromDismissalFeedback
      def perform(project_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::UpdateVulnerabilitiesFromDismissalFeedback.prepend_if_ee('EE::Gitlab::BackgroundMigration::UpdateVulnerabilitiesFromDismissalFeedback')
