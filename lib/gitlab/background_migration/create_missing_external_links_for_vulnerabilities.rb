# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class CreateMissingExternalLinksForVulnerabilities < BatchedMigrationJob
      feature_category :vulnerability_management
      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::CreateMissingExternalLinksForVulnerabilities.prepend_mod
