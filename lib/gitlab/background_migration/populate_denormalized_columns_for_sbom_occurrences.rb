# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class PopulateDenormalizedColumnsForSbomOccurrences < BatchedMigrationJob
      feature_category :dependency_management

      def perform
        # no-op for the FOSS version
      end
    end
  end
end

::Gitlab::BackgroundMigration::PopulateDenormalizedColumnsForSbomOccurrences.prepend_mod
