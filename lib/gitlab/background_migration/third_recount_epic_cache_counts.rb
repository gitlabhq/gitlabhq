# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class ThirdRecountEpicCacheCounts < Gitlab::BackgroundMigration::BatchedMigrationJob
      feature_category :database

      def perform; end
    end
    # rubocop: enable Style/Documentation
  end
end

# rubocop: disable Layout/LineLength
# we just want to re-enqueue the previous BackfillEpicCacheCounts migration,
# because it's a EE-only migation and it's a module, we just prepend new
# RecountEpicCacheCounts with existing batched migration module (which is same in both cases)
Gitlab::BackgroundMigration::ThirdRecountEpicCacheCounts.prepend_mod_with('Gitlab::BackgroundMigration::BackfillEpicCacheCounts')
# rubocop: enable Layout/LineLength
