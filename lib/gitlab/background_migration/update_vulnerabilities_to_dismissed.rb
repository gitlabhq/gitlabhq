# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class UpdateVulnerabilitiesToDismissed
      def perform(project_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::UpdateVulnerabilitiesToDismissed.prepend_if_ee('EE::Gitlab::BackgroundMigration::UpdateVulnerabilitiesToDismissed')
