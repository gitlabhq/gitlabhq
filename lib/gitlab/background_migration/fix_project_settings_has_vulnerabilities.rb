# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Fixes the project_settings#has_vulnerabilities data inconsistencies
    class FixProjectSettingsHasVulnerabilities < BatchedMigrationJob
      feature_category :vulnerability_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::FixProjectSettingsHasVulnerabilities.prepend_mod
