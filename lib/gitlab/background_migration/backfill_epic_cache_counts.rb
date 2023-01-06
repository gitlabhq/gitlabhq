# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class BackfillEpicCacheCounts < Gitlab::BackgroundMigration::BatchedMigrationJob
      feature_category :database

      def perform; end
    end
    # rubocop: enable Style/Documentation
  end
end

# rubocop: disable Layout/LineLength
Gitlab::BackgroundMigration::BackfillEpicCacheCounts.prepend_mod_with('Gitlab::BackgroundMigration::BackfillEpicCacheCounts')
# rubocop: enable Layout/LineLength
