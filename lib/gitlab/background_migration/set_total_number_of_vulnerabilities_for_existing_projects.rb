# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Sets the `vulnerability_count` column of `project_security_statistics` table.
    class SetTotalNumberOfVulnerabilitiesForExistingProjects < BatchedMigrationJob
      feature_category :vulnerability_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::SetTotalNumberOfVulnerabilitiesForExistingProjects.prepend_mod
