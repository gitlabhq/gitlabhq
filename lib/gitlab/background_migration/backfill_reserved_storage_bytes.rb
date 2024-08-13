# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillReservedStorageBytes < BatchedMigrationJob
      feature_category :global_search

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillReservedStorageBytes.prepend_mod
