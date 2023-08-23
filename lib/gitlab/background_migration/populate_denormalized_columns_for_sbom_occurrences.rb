# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop:disable Style/Documentation
    class PopulateDenormalizedColumnsForSbomOccurrences < BatchedMigrationJob
      feature_category :dependency_management

      def perform
        # no-op for the FOSS version
      end
    end
    # rubocop:enable Style/Documentation
  end
end

::Gitlab::BackgroundMigration::PopulateDenormalizedColumnsForSbomOccurrences.prepend_mod
